// get_arg_value: use @common (SoT)
// substring: use @common (SoT)
// trim_string: use @common.trim_ascii_spaces (SoT)

///|
fn lower_string(s : String) -> String {
  s.to_lower()
}

// parse_int: use @common (SoT)
// split_lines: use @common (SoT)

// join_lines: use @common (SoT)

///|
fn is_blank_line(line : String) -> Bool {
  line.trim().length() == 0
}

///|
fn normalize_spaces(text : String) -> String {
  let chars = text.to_array()
  let buf = StringBuilder::new()
  let mut last_space = false
  for ch in chars {
    let is_space = ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
    if is_space {
      if not(last_space) {
        buf.write_char(' ')
      }
      last_space = true
    } else {
      buf.write_char(ch)
      last_space = false
    }
  }
  @common.trim_ascii_spaces(buf.to_string())
}

///|
fn preview_text(text : String, max_len? : Int = 120) -> String {
  let normalized = normalize_spaces(text)
  if normalized.length() <= max_len {
    normalized
  } else {
    @common.substring(normalized, 0, max_len) + "..."
  }
}

///|
fn make_hash(parts : Array[String]) -> String {
  @cas_hash.compute_hash(parts.join("\u0000")).to_string()
}

///|
fn last_index_of(s : String, ch : Char) -> Int {
  let chars = s.to_array()
  let mut idx = -1
  for i, current in chars {
    if current == ch {
      idx = i
    }
  }
  idx
}

///|
fn contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn sort_strings(values : Array[String]) -> Array[String] {
  let sorted = values.copy()
  sorted.sort()
  sorted
}

///|
fn status_priority(status : String) -> Int {
  match status {
    "missing_doc" => 0
    "stale_doc" => 1
    "review_both" => 2
    _ => 3
  }
}
