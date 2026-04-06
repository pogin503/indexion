///|
fn split_once(text : String, delimiter : Char) -> (String, String)? {
  let chars = text.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == delimiter {
      return Some(
        (
          @common.substring(text, 0, i),
          @common.substring(text, i + 1, text.length()),
        ),
      )
    }
  }
  None
}

///|
fn replace_all(text : String, old : String, new_ : String) -> String {
  text.replace(old~, new=new_)
}

///|
fn extract_digits(text : String) -> String {
  let buf = StringBuilder::new()
  for ch in text.to_array() {
    if ch >= '0' && ch <= '9' {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

///|
fn feature_first(spec : @kgf_types.KGFSpec, name : String) -> String? {
  match spec.get_feature(name) {
    Some(values) => if values.length() > 0 { Some(values[0]) } else { None }
    None => None
  }
}

///|
fn feature_values(spec : @kgf_types.KGFSpec, name : String) -> Array[String] {
  match spec.get_feature(name) {
    Some(values) => values
    None => []
  }
}

///|
fn supported_sdd_specs(
  registry : @registry.KGFRegistry,
  explicit_format : String,
) -> Array[@kgf_types.KGFSpec] {
  if explicit_format != "auto" {
    match registry.get_spec(explicit_format) {
      Some(spec) =>
        if feature_first(spec, "sdd_profile") is Some(_) {
          return [spec]
        }
      None => ()
    }
    return []
  }
  let specs : Array[@kgf_types.KGFSpec] = []
  let languages = registry.get_languages()
  languages.sort()
  for language in languages {
    match registry.get_spec(language) {
      Some(spec) =>
        if feature_first(spec, "sdd_profile") is Some(_) {
          specs.push(spec)
        }
      None => ()
    }
  }
  specs
}

///|
fn source_requirement_id(
  path : String,
  section : @kgf_features.DocumentSection,
) -> String {
  path + "#" + section.anchor + ":L" + section.line.to_string()
}

///|
fn parse_requirement_heading(
  spec : @kgf_types.KGFSpec,
  heading : String,
  section : @kgf_features.DocumentSection,
  path : String,
) -> (String?, String, String?)? {
  let keyword = match feature_first(spec, "sdd_requirement_keyword") {
    Some(value) => value
    None => return None
  }
  let lowered = lower_ascii(heading)
  let lowered_keyword = lower_ascii(keyword)
  let mode = feature_first(spec, "sdd_requirement_id_mode").unwrap_or("")
  if mode == "numbered" {
    if !lowered.has_prefix(lowered_keyword) {
      return None
    }
    let body = trim(
      @common.substring(heading, keyword.length(), heading.length()),
    )
    match split_once(body, ':') {
      Some((left, right)) => {
        let digits = extract_digits(left)
        if digits.length() == 0 {
          return None
        }
        Some((Some("REQ-" + digits), trim(right), None))
      }
      None => None
    }
  } else if mode == "source-derived" {
    if !lowered.has_prefix(lowered_keyword + ":") {
      return None
    }
    let body = trim(
      @common.substring(heading, keyword.length() + 1, heading.length()),
    )
    let normative = if body.contains("SHALL") {
      Some("SHALL")
    } else if body.contains("MUST") {
      Some("MUST")
    } else if body.contains("SHOULD") {
      Some("SHOULD")
    } else {
      None
    }
    Some((Some(source_requirement_id(path, section)), body, normative))
  } else if mode == "explicit" {
    if !lowered.has_prefix(lowered_keyword) {
      return None
    }
    match split_once(heading, ':') {
      Some((left, right)) => Some((Some(trim(left)), trim(right), None))
      None => None
    }
  } else {
    None
  }
}

///|
fn is_meta_heading(spec : @kgf_types.KGFSpec, heading : String) -> Bool {
  let lowered = lower_ascii(heading)
  for value in feature_values(spec, "sdd_meta_heading") {
    if lowered == lower_ascii(value) {
      return true
    }
  }
  false
}

///|
fn is_criteria_heading(spec : @kgf_types.KGFSpec, heading : String) -> Bool {
  let lowered = lower_ascii(heading)
  match feature_first(spec, "sdd_criteria_heading") {
    Some(value) => lowered == lower_ascii(value)
    None => false
  }
}

///|
fn strip_marker_prefix(text : String, prefix : String) -> String {
  trim(@common.substring(text, prefix.length(), text.length()))
}

///|
fn parse_gwt_bullet(line : String) -> (String, String)? {
  let trimmed = trim(line)
  if !trimmed.has_prefix("-") {
    return None
  }
  let body = replace_all(
    trim(@common.substring(trimmed, 1, trimmed.length())),
    "**",
    "",
  )
  let lowered = lower_ascii(body)
  if lowered.has_prefix("given ") {
    return Some(("given", strip_marker_prefix(body, "GIVEN ")))
  }
  if lowered.has_prefix("when ") {
    return Some(("when", strip_marker_prefix(body, "WHEN ")))
  }
  if lowered.has_prefix("then ") {
    return Some(("then", strip_marker_prefix(body, "THEN ")))
  }
  None
}

///|
fn parse_checkbox_bullet(line : String) -> String? {
  let trimmed = trim(line)
  if !trimmed.has_prefix("-") {
    return None
  }
  let mut body = trim(@common.substring(trimmed, 1, trimmed.length()))
  if body.has_prefix("[ ]") || body.has_prefix("[x]") || body.has_prefix("[X]") {
    body = trim(@common.substring(body, 3, body.length()))
  }
  body = replace_all(body, "**", "")
  if body.length() > 0 {
    Some(body)
  } else {
    None
  }
}

///|
fn parse_scenario_title(spec : @kgf_types.KGFSpec, heading : String) -> String? {
  let prefix = match feature_first(spec, "sdd_scenario_prefix") {
    Some(value) => value
    None => return None
  }
  let lowered = lower_ascii(heading)
  let lowered_prefix = lower_ascii(prefix)
  if lowered.has_prefix(lowered_prefix) {
    Some(trim(@common.substring(heading, prefix.length(), heading.length())))
  } else {
    None
  }
}

///|
fn section_body_lines(section : @kgf_features.DocumentSection) -> Array[String] {
  let lines = @common.split_lines(section.content)
  if lines.length() <= 1 {
    return []
  }
  let body : Array[String] = []
  for i = 1; i < lines.length(); i = i + 1 {
    body.push(lines[i])
  }
  body
}

///|
fn join_nonblank_lines(lines : Array[String]) -> String {
  let result : Array[String] = []
  for line in lines {
    let value = trim(line)
    if value.length() > 0 {
      result.push(value)
    }
  }
  @common.join_lines(result)
}

///|
fn parse_requirement_body(
  section : @kgf_features.DocumentSection,
) -> (String, Array[String], Array[String], Array[String], Array[String]) {
  let description_lines : Array[String] = []
  let criteria : Array[String] = []
  let given : Array[String] = []
  let when_ : Array[String] = []
  let then_ : Array[String] = []
  for line in section_body_lines(section) {
    match parse_gwt_bullet(line) {
      Some(("given", text)) => given.push(text)
      Some(("when", text)) => when_.push(text)
      Some(("then", text)) => then_.push(text)
      Some(_) => ()
      None => {
        let trimmed = trim(line)
        if trimmed.has_prefix("-") {
          let item = replace_all(
            trim(@common.substring(trimmed, 1, trimmed.length())),
            "**",
            "",
          )
          if item.length() > 0 {
            criteria.push(item)
          }
        } else if !is_blank(trimmed) {
          description_lines.push(trimmed)
        }
      }
    }
  }
  (join_nonblank_lines(description_lines), criteria, given, when_, then_)
}

///|
fn parse_scenario_body(
  section : @kgf_features.DocumentSection,
) -> (Array[String], Array[String], Array[String]) {
  let given : Array[String] = []
  let when_ : Array[String] = []
  let then_ : Array[String] = []
  for line in section_body_lines(section) {
    match parse_gwt_bullet(line) {
      Some(("given", text)) => given.push(text)
      Some(("when", text)) => when_.push(text)
      Some(("then", text)) => then_.push(text)
      Some(_) => ()
      None => ()
    }
  }
  (given, when_, then_)
}

///|
fn parse_structured_document(
  path : String,
  spec : @kgf_types.KGFSpec,
  sections : Array[@kgf_features.DocumentSection],
) -> (Array[RequirementNode], Array[ScenarioNode], String)? {
  let requirements : Array[RequirementNode] = []
  let scenarios : Array[ScenarioNode] = []
  let source_format = spec.get_language()
  let mut current_requirement : RequirementNode? = None
  for section in sections {
    let heading = trim(section.title)
    if is_meta_heading(spec, heading) {
      continue
    }
    match parse_requirement_heading(spec, heading, section, path) {
      Some((requirement_id, title, normative)) => {
        let (description, criteria, given, when_, then_) = parse_requirement_body(
          section,
        )
        let requirement = {
          id: requirement_id.unwrap_or(source_requirement_id(path, section)),
          title,
          description,
          normative,
          source_format,
          source_file: path,
          source_start_line: section.line,
          source_end_line: section.end_line,
          criteria,
        }
        requirements.push(requirement)
        if given.length() > 0 || when_.length() > 0 || then_.length() > 0 {
          scenarios.push({
            id: requirement.id + "::SCN-" + (scenarios.length() + 1).to_string(),
            title: requirement.title + " Scenario",
            given,
            when_,
            then_,
            parent_req: requirement.id,
            source_file: path,
            source_start_line: section.line,
            source_end_line: section.end_line,
          })
        }
        current_requirement = Some(requirement)
      }
      None =>
        match parse_scenario_title(spec, heading) {
          Some(title) => {
            guard current_requirement is Some(requirement) else { continue }
            let (given, when_, then_) = parse_scenario_body(section)
            if given.length() == 0 && when_.length() == 0 && then_.length() == 0 {
              continue
            }
            scenarios.push({
              id: requirement.id +
              "::SCN-" +
              (scenarios.length() + 1).to_string(),
              title,
              given,
              when_,
              then_,
              parent_req: requirement.id,
              source_file: path,
              source_start_line: section.line,
              source_end_line: section.end_line,
            })
          }
          None => ()
        }
    }
  }
  if requirements.length() == 0 {
    None
  } else {
    Some((requirements, scenarios, source_format))
  }
}

///|
fn parse_document_with_criteria_section(
  path : String,
  spec : @kgf_types.KGFSpec,
  sections : Array[@kgf_features.DocumentSection],
) -> (Array[RequirementNode], Array[ScenarioNode], String)? {
  let requirements : Array[RequirementNode] = []
  let scenarios : Array[ScenarioNode] = []
  let source_format = spec.get_language()
  let mut current_id = ""
  let mut current_title = ""
  let mut current_description : Array[String] = []
  let mut current_criteria : Array[String] = []
  let mut current_start_line = 0
  let mut current_end_line = 0

  fn flush_requirement(
    requirements : Array[RequirementNode],
    path : String,
    source_format : String,
    current_id : String,
    current_title : String,
    current_description : Array[String],
    current_criteria : Array[String],
    current_start_line : Int,
    current_end_line : Int,
  ) -> Unit {
    if current_id.length() == 0 {
      return
    }
    requirements.push({
      id: current_id,
      title: current_title,
      description: join_nonblank_lines(current_description),
      normative: None,
      source_format,
      source_file: path,
      source_start_line: current_start_line,
      source_end_line: current_end_line,
      criteria: current_criteria.copy(),
    })
  }

  for section in sections {
    let heading = trim(section.title)
    if is_meta_heading(spec, heading) && !is_criteria_heading(spec, heading) {
      continue
    }
    if is_criteria_heading(spec, heading) {
      for line in section_body_lines(section) {
        match parse_checkbox_bullet(line) {
          Some(item) => current_criteria.push(item)
          None => ()
        }
      }
      if current_id.length() > 0 {
        current_end_line = section.end_line
      }
      continue
    }
    match parse_requirement_heading(spec, heading, section, path) {
      Some((requirement_id, title, _normative)) => {
        flush_requirement(
          requirements, path, source_format, current_id, current_title, current_description,
          current_criteria, current_start_line, current_end_line,
        )
        current_id = requirement_id.unwrap_or(
          source_requirement_id(path, section),
        )
        current_title = title
        current_description = []
        current_criteria = []
        current_start_line = section.line
        current_end_line = section.end_line
        for line in section_body_lines(section) {
          match parse_checkbox_bullet(line) {
            Some(item) => current_criteria.push(item)
            None => {
              let trimmed = trim(line)
              if !is_blank(trimmed) {
                current_description.push(trimmed)
              }
            }
          }
        }
      }
      None => ()
    }
  }
  flush_requirement(
    requirements, path, source_format, current_id, current_title, current_description,
    current_criteria, current_start_line, current_end_line,
  )
  if requirements.length() == 0 {
    None
  } else {
    Some((requirements, scenarios, source_format))
  }
}

///|
fn parse_document_with_spec(
  path : String,
  spec : @kgf_types.KGFSpec,
  content : String,
) -> (Array[RequirementNode], Array[ScenarioNode], String)? {
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  let tokens = lexer.tokenize(content)
  let sections = @kgf_features.extract_document_sections(
    tokens,
    content,
    spec=Some(spec),
  )
  if sections.length() == 0 {
    return None
  }
  if feature_first(spec, "sdd_criteria_heading") is Some(_) {
    parse_document_with_criteria_section(path, spec, sections)
  } else {
    parse_structured_document(path, spec, sections)
  }
}

///|
fn parse_spec_document(
  path : String,
  content : String,
  explicit_format : String,
  registry : @registry.KGFRegistry,
) -> (Array[RequirementNode], Array[ScenarioNode], String) {
  let specs = supported_sdd_specs(registry, explicit_format)
  if specs.length() == 0 {
    return ([], [], "unsupported")
  }
  for spec in specs {
    match parse_document_with_spec(path, spec, content) {
      Some(result) => return result
      None => ()
    }
  }
  ([], [], "unsupported")
}
