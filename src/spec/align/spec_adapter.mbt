///|
fn supports_document_interpretation(spec : @kgf_types.KGFSpec) -> Bool {
  spec.get_semantic("DocumentSection") is Some(_)
}

///|
fn supported_document_specs(
  registry : @registry.KGFRegistry,
  explicit_format : String,
) -> Array[@kgf_types.KGFSpec] {
  if explicit_format != "auto" {
    match registry.get_spec(explicit_format) {
      Some(spec) => if supports_document_interpretation(spec) { return [spec] }
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
        if supports_document_interpretation(spec) {
          specs.push(spec)
        }
      None => ()
    }
  }
  specs
}

///|
fn json_string_field(payload : Map[String, Json], key : String) -> String? {
  match payload.get(key) {
    Some(String(value)) => Some(value)
    Some(Number(value, ..)) => Some(value.to_int().to_string())
    _ => None
  }
}

///|
fn json_int_field(payload : Map[String, Json], key : String) -> Int {
  match payload.get(key) {
    Some(Number(value, ..)) => value.to_int()
    Some(String(value)) => parse_int_or_zero(value)
    _ => 0
  }
}

///|
fn parse_int_or_zero(text : String) -> Int {
  let mut value = 0
  let mut has_digit = false
  for ch in text {
    if ch >= '0' && ch <= '9' {
      value = value * 10 + (ch.to_int() - '0'.to_int())
      has_digit = true
    } else {
      return 0
    }
  }
  if has_digit {
    value
  } else {
    0
  }
}

///|
fn json_string_array_field(
  payload : Map[String, Json],
  key : String,
) -> Array[String] {
  match payload.get(key) {
    Some(Array(values)) => {
      let result : Array[String] = []
      for value in values {
        match value {
          String(text) => result.push(text)
          Number(n, ..) => result.push(n.to_int().to_string())
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

///|
fn load_spec_nodes(
  path : String,
  content : String,
  explicit_format : String,
  registry : @registry.KGFRegistry,
) -> (Array[RequirementNode], Array[ScenarioNode], String) {
  let specs = supported_document_specs(registry, explicit_format)
  if specs.length() == 0 {
    return ([], [], "unsupported")
  }
  for spec in specs {
    let interpreted = @doc_structure.interpret_document(content, path, spec)
    if interpreted.facts.length() == 0 {
      continue
    }
    let source_format = spec.get_language()
    let requirements : Array[RequirementNode] = []
    let scenarios : Array[ScenarioNode] = []
    let criteria_by_requirement : Map[String, Array[String]] = {}
    for fact in interpreted.facts {
      let ty = fact.kind
      let payload = fact.payload
      if ty == "document_requirement" {
        let id = json_string_field(payload, "id").unwrap_or("")
        let title = json_string_field(payload, "title").unwrap_or("")
        if id.length() == 0 || title.length() == 0 {
          continue
        }
        requirements.push({
          id,
          title,
          description: json_string_field(payload, "description").unwrap_or(""),
          normative: json_string_field(payload, "normative"),
          source_format,
          source_file: path,
          source_start_line: json_int_field(payload, "line"),
          source_end_line: json_int_field(payload, "end_line"),
          criteria: [],
        })
      } else if ty == "document_scenario" {
        let parent_id = json_string_field(payload, "parent_id").unwrap_or("")
        if parent_id.length() == 0 {
          continue
        }
        scenarios.push({
          id: parent_id + "::SCN-" + (scenarios.length() + 1).to_string(),
          title: json_string_field(payload, "title").unwrap_or("Scenario"),
          given: json_string_array_field(payload, "given"),
          when_: json_string_array_field(payload, "when"),
          then_: json_string_array_field(payload, "then"),
          parent_req: parent_id,
          source_file: path,
          source_start_line: json_int_field(payload, "line"),
          source_end_line: json_int_field(payload, "end_line"),
        })
      } else if ty == "document_requirement_criteria" {
        let parent_id = json_string_field(payload, "parent_id").unwrap_or("")
        if parent_id.length() == 0 {
          continue
        }
        let merged = match criteria_by_requirement.get(parent_id) {
          Some(existing) => existing.copy()
          None => []
        }
        for item in json_string_array_field(payload, "criteria") {
          merged.push(item)
        }
        criteria_by_requirement.set(parent_id, merged)
      }
    }
    if requirements.length() == 0 {
      continue
    }
    let finalized : Array[RequirementNode] = []
    for requirement in requirements {
      let criteria = match criteria_by_requirement.get(requirement.id) {
        Some(items) => items.copy()
        None => []
      }
      finalized.push({ ..requirement, criteria, })
    }
    return (finalized, scenarios, source_format)
  }
  ([], [], "unsupported")
}
