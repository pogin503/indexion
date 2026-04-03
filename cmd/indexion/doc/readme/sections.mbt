///|
/// Section extraction from Markdown README files.

///|
/// Extract specified sections from Markdown content.
/// Returns content of matching sections joined together.
pub fn extract_sections(
  content : String,
  section_names : Array[String],
) -> String {
  if section_names.is_empty() {
    return content
  }
  let normalized_names = normalize_section_names(section_names)
  let lines = split_content_lines(content)
  let result = StringBuilder::new()
  let mut current_section = ""
  let mut in_matching_section = false
  let mut first_output = true
  for line in lines {
    if is_heading_line(line) {
      let heading_text = extract_heading_text(line)
      current_section = normalize_section_name(heading_text)
      in_matching_section = contains_section_name(
        normalized_names, current_section,
      )
      if in_matching_section {
        if !first_output {
          result.write_string("\n")
        }
        first_output = false
      }
    }
    if in_matching_section {
      result.write_string(line)
      result.write_char('\n')
    }
  }
  result.to_string()
}

///|
/// Extract overview/summary section (content before first ## heading).
pub fn extract_overview(content : String) -> String {
  let lines = split_content_lines(content)
  let result = StringBuilder::new()
  let mut found_first_heading = false
  let mut skipped_title = false
  for line in lines {
    // Skip the # title line
    if !skipped_title && line.has_prefix("# ") {
      skipped_title = true
      continue
    }
    // Stop at first ## heading
    if line.has_prefix("## ") {
      found_first_heading = true
      break
    }
    if skipped_title {
      result.write_string(line)
      result.write_char('\n')
    }
  }
  let _ = found_first_heading
  @common.trim_ascii_spaces(result.to_string())
}

///|
fn normalize_section_names(names : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for name in names {
    result.push(normalize_section_name(name))
  }
  result
}

///|
fn normalize_section_name(name : String) -> String {
  // Lowercase and remove non-alphanumeric characters
  let chars = name.to_array()
  let result : Array[Char] = []
  for ch in chars {
    if is_alpha_char(ch) || is_digit_char(ch) {
      result.push(to_lower_char(ch))
    }
  }
  String::from_array(result)
}

///|
fn is_heading_line(line : String) -> Bool {
  line.has_prefix("## ") || line.has_prefix("### ")
}

///|
fn extract_heading_text(line : String) -> String {
  let chars = line.to_array()
  let mut start = 0
  // Skip # characters and spaces
  while start < chars.length() && (chars[start] == '#' || chars[start] == ' ') {
    start = start + 1
  }
  if start >= chars.length() {
    return ""
  }
  let result : Array[Char] = []
  for i = start; i < chars.length(); i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result)
}

///|
fn contains_section_name(names : Array[String], name : String) -> Bool {
  for n in names {
    if n == name {
      return true
    }
  }
  false
}

///|
fn split_content_lines(content : String) -> Array[String] {
  let lines : Array[String] = []
  let current : Array[Char] = []
  for ch in content.to_array() {
    if ch == '\n' {
      lines.push(String::from_array(current))
      current.clear()
    } else {
      current.push(ch)
    }
  }
  if current.length() > 0 {
    lines.push(String::from_array(current))
  }
  lines
}

///|
/// Count the heading level of a line (number of leading # characters).
/// Returns 0 if not a heading.
fn heading_level(line : String) -> Int {
  let chars = line.to_array()
  let mut count = 0
  while count < chars.length() && chars[count] == '#' {
    count = count + 1
  }
  // Must be followed by a space to be a valid heading
  if count > 0 && count < chars.length() && chars[count] == ' ' {
    count
  } else {
    0
  }
}

///|
/// Extract heading text (without # prefix).
fn heading_text(line : String) -> String {
  let level = heading_level(line)
  if level == 0 {
    return ""
  }
  let chars = line.to_array()
  let start = level + 1 // skip # chars and space
  if start >= chars.length() {
    return ""
  }
  let result : Array[Char] = []
  for i = start; i < chars.length(); i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result)
}

///|
/// Collect lines into a trimmed text block.
fn lines_to_text(lines : Array[String]) -> String {
  let buf = StringBuilder::new()
  for i, line in lines {
    if i > 0 {
      buf.write_char('\n')
    }
    buf.write_string(line)
  }
  @common.trim_ascii_spaces(buf.to_string())
}

///|
/// Parse Markdown content into a hierarchical array of PlanSections.
/// Heading levels are represented as nesting depth, not literal # counts.
pub fn parse_markdown_to_sections(
  content : String,
) -> Array[@plan_types.PlanSection] {
  let lines = split_content_lines(content)
  let result : Array[@plan_types.PlanSection] = []
  // Find the minimum heading level in the document (base level), skipping code fences
  let mut min_level = 99
  let mut in_fence_scan = false
  for line in lines {
    if line.has_prefix("```") || line.has_prefix("~~~") {
      in_fence_scan = !in_fence_scan
      continue
    }
    if !in_fence_scan {
      let level = heading_level(line)
      if level > 0 && level < min_level {
        min_level = level
      }
    }
  }
  if min_level == 99 {
    // No headings at all — return entire content as single anonymous section
    let text = @common.trim_ascii_spaces(content)
    if text.length() > 0 {
      result.push(
        @plan_types.PlanSection::new(
          "",
          "",
          @plan_types.SectionContent::text(text),
        ),
      )
    }
    return result
  }
  // Parse into flat section list: (heading_level, heading_text, content_lines)
  // Tracks code fences to avoid treating # inside code blocks as headings
  let flat : Array[(Int, String, Array[String])] = []
  let mut current_lines : Array[String] = []
  let mut current_heading = ""
  let mut current_level = 0
  let mut in_code_fence = false
  for line in lines {
    // Track code fences (``` or ~~~)
    if line.has_prefix("```") || line.has_prefix("~~~") {
      in_code_fence = !in_code_fence
      current_lines.push(line)
      continue
    }
    let level = heading_level(line)
    if level > 0 && !in_code_fence {
      // Flush previous section
      if current_heading.length() > 0 || current_lines.length() > 0 {
        flat.push((current_level, current_heading, current_lines))
      }
      current_heading = heading_text(line)
      current_level = level
      current_lines = []
    } else {
      current_lines.push(line)
    }
  }
  // Flush last section
  if current_heading.length() > 0 || current_lines.length() > 0 {
    flat.push((current_level, current_heading, current_lines))
  }
  // Build nested structure recursively
  build_nested_sections(flat, 0, flat.length(), min_level)
}

///|
/// Build nested PlanSections from a flat section list.
/// Processes sections from index `start` to `end`, grouping children under
/// sections at `base_level`.
fn build_nested_sections(
  flat : Array[(Int, String, Array[String])],
  start : Int,
  end : Int,
  base_level : Int,
) -> Array[@plan_types.PlanSection] {
  let result : Array[@plan_types.PlanSection] = []
  let mut i = start
  while i < end {
    let (level, heading, lines) = flat[i]
    if level == 0 {
      // Pre-heading content (level 0 means no heading)
      let text = lines_to_text(lines)
      if text.length() > 0 {
        result.push(
          @plan_types.PlanSection::new(
            "",
            "",
            @plan_types.SectionContent::text(text),
          ),
        )
      }
      i = i + 1
    } else if level == base_level {
      // Find where this section ends (next section at same or higher level)
      let mut section_end = i + 1
      while section_end < end {
        let (next_level, _, _) = flat[section_end]
        if next_level > 0 && next_level <= base_level {
          break
        }
        section_end = section_end + 1
      }
      // Build content: own text + nested children
      let own_text = lines_to_text(lines)
      let children = build_nested_sections(
        flat,
        i + 1,
        section_end,
        base_level + 1,
      )
      let id = normalize_section_name(heading)
      if children.length() == 0 {
        // Leaf section: just text content
        result.push(
          @plan_types.PlanSection::new(
            id,
            heading,
            @plan_types.SectionContent::text(own_text),
          ),
        )
      } else {
        // Section with children: own text as anonymous first child + nested children
        let nested : Array[@plan_types.PlanSection] = []
        if own_text.length() > 0 {
          nested.push(
            @plan_types.PlanSection::new(
              "",
              "",
              @plan_types.SectionContent::text(own_text),
            ),
          )
        }
        for child in children {
          nested.push(child)
        }
        result.push(
          @plan_types.PlanSection::new(
            id,
            heading,
            @plan_types.SectionContent::nested(nested),
          ),
        )
      }
      i = section_end
    } else {
      // Section at deeper level than base — treat as child
      // This shouldn't normally happen at the top call, but handle gracefully
      let text = lines_to_text(lines)
      if text.length() > 0 || heading.length() > 0 {
        result.push(
          @plan_types.PlanSection::new(
            normalize_section_name(heading),
            heading,
            @plan_types.SectionContent::text(text),
          ),
        )
      }
      i = i + 1
    }
  }
  result
}

///|
/// Filter parsed sections by section names (e.g., ["overview", "usage"]).
/// "overview" matches the anonymous pre-heading section.
pub fn filter_parsed_sections(
  sections : Array[@plan_types.PlanSection],
  names : Array[String],
) -> Array[@plan_types.PlanSection] {
  if names.is_empty() {
    return sections
  }
  let normalized = normalize_section_names(names)
  let result : Array[@plan_types.PlanSection] = []
  let include_overview = contains_section_name(normalized, "overview")
  for section in sections {
    if section.heading.length() == 0 {
      // Anonymous section = overview
      if include_overview {
        result.push(section)
      }
    } else {
      let name = normalize_section_name(section.heading)
      if contains_section_name(normalized, name) {
        result.push(section)
      }
    }
  }
  result
}

///|
fn is_alpha_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

///|
fn is_digit_char(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn to_lower_char(ch : Char) -> Char {
  if ch >= 'A' && ch <= 'Z' {
    (ch.to_int() + 32).unsafe_to_char()
  } else {
    ch
  }
}
