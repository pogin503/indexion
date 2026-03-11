///|
fn get_arg_value(arg : String, prefix_len : Int) -> String {
  substring(arg, prefix_len, arg.length())
}

///|
fn substring(s : String, start : Int, end : Int) -> String {
  let chars = s.to_array()
  let actual_start = if start < 0 { 0 } else { start }
  let capped_end = if end > chars.length() { chars.length() } else { end }
  if actual_start >= capped_end {
    return ""
  }
  let buf = StringBuilder::new(size_hint=capped_end - actual_start)
  for i = actual_start; i < capped_end; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
fn trim_string(s : String) -> String {
  s.trim().to_string()
}

///|
fn lower_string(s : String) -> String {
  s.to_lower()
}

///|
fn parse_int(s : String) -> Int {
  let chars = trim_string(s).to_array()
  if chars.length() == 0 {
    return 0
  }
  let mut idx = 0
  let mut negative = false
  if chars[0] == '-' {
    negative = true
    idx = 1
  }
  let mut result = 0
  while idx < chars.length() {
    let ch = chars[idx]
    if ch < '0' || ch > '9' {
      break
    }
    result = result * 10 + (ch.to_int() - '0'.to_int())
    idx = idx + 1
  }
  if negative {
    -result
  } else {
    result
  }
}

///|
fn split_lines(content : String) -> Array[String] {
  let lines : Array[String] = []
  let chars = content.to_array()
  let current : Array[Char] = []
  let mut i = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch == '\n' {
      lines.push(String::from_array(current))
      current.clear()
    } else if ch == '\r' {
      // Normalize CRLF and lone CR.
      if i + 1 < chars.length() && chars[i + 1] == '\n' {
        ignore(i)
      }
      lines.push(String::from_array(current))
      current.clear()
    } else {
      current.push(ch)
    }
    i = i + 1
  }
  if current.length() > 0 || content.length() == 0 {
    lines.push(String::from_array(current))
  }
  lines
}

///|
fn join_lines(lines : Array[String]) -> String {
  let buf = StringBuilder::new()
  for i, line in lines {
    if i > 0 {
      buf.write_string("\n")
    }
    buf.write_string(line)
  }
  buf.to_string()
}

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
  trim_string(buf.to_string())
}

///|
fn preview_text(text : String, max_len? : Int = 120) -> String {
  let normalized = normalize_spaces(text)
  if normalized.length() <= max_len {
    normalized
  } else {
    substring(normalized, 0, max_len) + "..."
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
