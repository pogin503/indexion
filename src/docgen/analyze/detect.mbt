// File content detection and KGF spec selection.
// Supports both KGF registry-based detection and fallback hardcoded patterns.

///|
/// Extract file extension from path (without dot).
pub fn extract_extension(path : String) -> String {
  let chars = path.to_array()
  let mut last_dot = -1
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '.' {
      last_dot = i
    } else if chars[i] == '/' || chars[i] == '\\' {
      last_slash = i
    }
  }
  if last_dot > last_slash && last_dot < chars.length() - 1 {
    let result : Array[Char] = []
    for i = last_dot + 1; i < chars.length(); i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    ""
  }
}

///|
/// Detect language from file extension using KGF registry.
/// Returns language name from KGF spec if found.
pub fn detect_from_registry(
  registry : @registry.KGFRegistry,
  path : String,
) -> String? {
  registry.detect_from_path(path)
}

///|
/// Detect language from file extension (fallback).
fn detect_from_extension(ext : String) -> DetectedLang {
  match ext {
    "ts" | "tsx" | "mts" | "cts" => DetectedLang::TypeScript
    "js" | "jsx" | "mjs" | "cjs" => DetectedLang::JavaScript
    "py" | "pyi" => DetectedLang::Python
    "mbt" => DetectedLang::MoonBit
    "go" => DetectedLang::Go
    "rs" => DetectedLang::Rust
    "md" | "markdown" => DetectedLang::Markdown
    "html" | "htm" => DetectedLang::Html
    "css" | "scss" | "sass" => DetectedLang::Css
    "sql" => DetectedLang::Sql
    "json" => DetectedLang::Json
    "yaml" | "yml" => DetectedLang::Yaml
    _ => DetectedLang::Unknown
  }
}

///|
/// Check if content matches any of the given patterns.
fn has_any_pattern(content : String, patterns : FixedArray[String]) -> Bool {
  for pattern in patterns {
    if has_pattern(content, pattern) {
      return true
    }
  }
  false
}

///|
/// Language signature patterns for content-based detection.
/// Each entry: (DetectedLang, check function).
let lang_signatures : Array[
  (DetectedLang, (String) -> Bool),
] = [
  // Order matters: more specific languages first to avoid false positives
  (
    DetectedLang::MoonBit,
    fn(c) {
      has_any_pattern(c, ["fn ", "pub fn ", "struct ", "enum ", "///|", "derive("])
    },
  ),
  (
    DetectedLang::Rust,
    fn(c) {
      (has_pattern(c, "fn ") && has_pattern(c, "-> ")) ||
      has_any_pattern(c, ["impl ", "use ", "mod ", "pub fn ", "#["])
    },
  ),
  (
    DetectedLang::Go,
    fn(c) {
      has_any_pattern(c, ["package ", "func ", "import ("]) ||
      (has_pattern(c, "type ") && has_pattern(c, " struct {"))
    },
  ),
  (
    DetectedLang::Python,
    fn(c) {
      has_any_pattern(
        c,
        ["def ", "class ", "import ", "from ", "if __name__", "\"\"\""],
      )
    },
  ),
  (
    DetectedLang::TypeScript,
    fn(c) {
      has_any_pattern(
        c,
        [
          "import ", "export ", "function ", "const ", "class ", "interface ",
          "type ", "=> {",
        ],
      )
    },
  ),
  (
    DetectedLang::Html,
    fn(c) {
      has_any_pattern(c, ["<!DOCTYPE", "<html", "<head", "<body"])
    },
  ),
  (
    DetectedLang::Css,
    fn(c) {
      has_pattern(c, "{") &&
      has_any_pattern(
        c,
        ["color:", "background:", "margin:", "padding:", "display:"],
      )
    },
  ),
  (
    DetectedLang::Markdown,
    fn(c) {
      has_any_pattern(c, ["# ", "## ", "```"]) ||
      (has_pattern(c, "- ") && has_pattern(c, "\n- "))
    },
  ),
  (
    DetectedLang::Sql,
    fn(c) {
      let upper = to_upper(c)
      has_any_pattern(
        upper,
        ["SELECT ", "CREATE TABLE", "INSERT INTO", "UPDATE ", "DELETE FROM"],
      )
    },
  ),
]

///|
/// Detect language from file content using signature table.
fn detect_from_content(content : String) -> DetectedLang {
  for entry in lang_signatures {
    let (lang, check) = entry
    if check(content) {
      return lang
    }
  }
  DetectedLang::Unknown
}

///|
/// Detect file language using both extension and content analysis (legacy).
pub fn detect_language(path : String, content : String) -> DetectedLang {
  let ext = extract_extension(path)
  let from_ext = detect_from_extension(ext)
  if from_ext != DetectedLang::Unknown {
    return from_ext
  }
  detect_from_content(content)
}

///|
/// Detect language using KGF registry with fallback to legacy detection.
pub fn detect_language_with_registry(
  registry : @registry.KGFRegistry,
  path : String,
  content : String,
) -> String {
  // Try registry-based detection first
  match detect_from_registry(registry, path) {
    Some(lang) => lang
    None => {
      // Fall back to legacy detection
      let detected = detect_language(path, content)
      detected.to_string()
    }
  }
}

///|
/// Get doc spec name using KGF registry.
pub fn get_doc_spec_with_registry(
  registry : @registry.KGFRegistry,
  lang : String,
) -> String {
  registry.get_doc_spec_name(lang)
}

///|
/// Analyze a file and return FileInfo with spec selection.
/// Note: For filename-based patterns (e.g., moon.pkg), use analyze_file_with_registry instead.
pub fn analyze_file(path : String, content : String) -> FileInfo {
  let ext = extract_extension(path)
  let lang = detect_language(path, content)
  let spec_name = lang.doc_spec_name()
  FileInfo::new(path, lang, ext, spec_name)
}

///|
/// Analyze a file using KGF registry.
pub fn analyze_file_with_registry(
  registry : @registry.KGFRegistry,
  path : String,
  content : String,
) -> FileInfo {
  let ext = extract_extension(path)
  let lang_str = detect_language_with_registry(registry, path, content)
  let spec_name = get_doc_spec_with_registry(registry, lang_str)
  // Convert lang string to DetectedLang for compatibility
  let lang = lang_string_to_detected(lang_str)
  FileInfo::new(path, lang, ext, spec_name)
}

///|
/// Convert language string to DetectedLang.
fn lang_string_to_detected(lang : String) -> DetectedLang {
  match lang {
    "typescript" => DetectedLang::TypeScript
    "javascript" => DetectedLang::JavaScript
    "python" => DetectedLang::Python
    "moonbit" | "moonbit-doc" => DetectedLang::MoonBit
    "go" => DetectedLang::Go
    "rust" => DetectedLang::Rust
    "markdown" => DetectedLang::Markdown
    "html" => DetectedLang::Html
    "css" => DetectedLang::Css
    "sql" => DetectedLang::Sql
    "json" => DetectedLang::Json
    "yaml" => DetectedLang::Yaml
    _ => DetectedLang::Unknown
  }
}

///|
/// Check if string contains a pattern.
fn has_pattern(s : String, pattern : String) -> Bool {
  find_substring(s, pattern) >= 0
}

///|
/// Find substring index.
fn find_substring(s : String, pattern : String) -> Int {
  let s_chars = s.to_array()
  let p_chars = pattern.to_array()
  if p_chars.length() == 0 || s_chars.length() < p_chars.length() {
    return -1
  }
  for i = 0; i <= s_chars.length() - p_chars.length(); i = i + 1 {
    let mut found = true
    for j = 0; j < p_chars.length(); j = j + 1 {
      if s_chars[i + j] != p_chars[j] {
        found = false
        break
      }
    }
    if found {
      return i
    }
  }
  -1
}

///|
/// Convert string to uppercase (ASCII only).
fn to_upper(s : String) -> String {
  let chars = s.to_array()
  let result : Array[Char] = []
  for c in chars {
    let code = c.to_int()
    if code >= 97 && code <= 122 {
      result.push(Int::unsafe_to_char(code - 32))
    } else {
      result.push(c)
    }
  }
  String::from_array(result)
}
