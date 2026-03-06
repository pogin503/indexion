///|
/// Template processing for documentation generation.
/// Supports simple placeholder substitution:
/// - `{{include:path}}` - Include file contents
/// - `{{packages}}` - All discovered packages (uses CLI --include/--exclude for filtering)

///|
/// Context for template rendering.
pub struct TemplateContext {
  base_dir : String
  packages : Array[(PackageInfo, ExtractedDoc)]
}

///|
pub fn TemplateContext::new(
  base_dir : String,
  packages : Array[(PackageInfo, ExtractedDoc)],
) -> TemplateContext {
  { base_dir, packages }
}

///|
/// Render a template string with the given context.
pub fn render_template(template : String, ctx : TemplateContext) -> String {
  let result = StringBuilder::new()
  let chars = template.to_array()
  let mut i = 0
  while i < chars.length() {
    if i + 1 < chars.length() && chars[i] == '{' && chars[i + 1] == '{' {
      let start = i + 2
      let mut end = start
      while end + 1 < chars.length() &&
            not(chars[end] == '}' && chars[end + 1] == '}') {
        end = end + 1
      }
      if end + 1 < chars.length() {
        let placeholder = extract_substring(chars, start, end)
        let replacement = resolve_placeholder(placeholder, ctx)
        result.write_string(replacement)
        i = end + 2
      } else {
        result.write_char(chars[i])
        i = i + 1
      }
    } else {
      result.write_char(chars[i])
      i = i + 1
    }
  }
  result.to_string()
}

///|
fn extract_substring(chars : Array[Char], start : Int, end : Int) -> String {
  let buf : Array[Char] = []
  for j = start; j < end; j = j + 1 {
    buf.push(chars[j])
  }
  String::from_array(buf)
}

///|
/// Resolve a placeholder to its value.
fn resolve_placeholder(placeholder : String, ctx : TemplateContext) -> String {
  if placeholder.has_prefix("include:") {
    let path = substring_from(placeholder, 8)
    resolve_include(path, ctx.base_dir)
  } else {
    match placeholder {
      "packages" => render_packages(ctx.packages, ctx.base_dir)
      "module_doc" => render_module_docs(ctx.packages)
      _ => "{{" + placeholder + "}}"
    }
  }
}

///|
/// Render {{module_doc}} - outputs only module-level documentation.
fn render_module_docs(packages : Array[(PackageInfo, ExtractedDoc)]) -> String {
  let buf = StringBuilder::new()
  for i, item in packages {
    let (_, doc) = item
    // Only output non-empty content that looks like module documentation
    let content = doc.content
    if content.length() > 0 && is_module_doc_content(content) {
      if buf.to_string().length() > 0 {
        buf.write_string("\n\n")
      }
      buf.write_string(content)
    }
    let _ = i
  }
  buf.to_string()
}

///|
/// Check if content looks like module-level documentation.
/// Module docs typically start with module description, not individual function/test docs.
fn is_module_doc_content(content : String) -> Bool {
  // Skip content that starts with test/function doc markers
  if content.has_prefix("///|") {
    // Check if it's just function docs (starts with ///| followed by short line)
    let lines = split_content_lines(content)
    if lines.length() > 0 {
      let first = lines[0]
      // Module docs usually have substantial description
      // Function docs are often short or start with lowercase
      if first.has_prefix("///|") && first.length() < 10 {
        return false
      }
    }
  }
  true
}

///|
fn substring_from(s : String, start : Int) -> String {
  let chars = s.to_array()
  if start >= chars.length() {
    return ""
  }
  let buf : Array[Char] = []
  for i = start; i < chars.length(); i = i + 1 {
    buf.push(chars[i])
  }
  String::from_array(buf)
}

///|
/// Resolve {{include:path}} placeholder.
fn resolve_include(path : String, base_dir : String) -> String {
  let full_path = if path.has_prefix("/") {
    path
  } else {
    base_dir + "/" + path
  }
  @fs.read_file_to_string(full_path) catch {
    _ => ""
  }
}

///|
/// Render {{packages}} - outputs each package's documentation content.
fn render_packages(
  packages : Array[(PackageInfo, ExtractedDoc)],
  base_dir : String,
) -> String {
  if packages.length() == 0 {
    return ""
  }
  let buf = StringBuilder::new()
  for i, item in packages {
    let (pkg, doc) = item
    if i > 0 {
      buf.write_string("\n---\n\n")
    }
    // Output package path as heading
    let rel_path = make_relative_path(pkg.path, base_dir)
    buf.write_string("### ")
    buf.write_string(rel_path)
    buf.write_string("\n\n")
    // Output document content
    buf.write_string(doc.content)
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// Make path relative to base_dir.
fn make_relative_path(path : String, base_dir : String) -> String {
  let normalized_base = if base_dir == "." || base_dir == "./" {
    ""
  } else {
    let b = if base_dir.has_suffix("/") { base_dir } else { base_dir + "/" }
    b
  }
  if normalized_base.length() > 0 && path.has_prefix(normalized_base) {
    substring_from(path, normalized_base.length())
  } else if path.has_prefix("./") {
    substring_from(path, 2)
  } else {
    path
  }
}

///|
/// Load and render a template file.
pub fn render_template_file(
  template_path : String,
  ctx : TemplateContext,
) -> String? {
  try {
    let template = @fs.read_file_to_string(template_path)
    Some(render_template(template, ctx))
  } catch {
    _ => None
  }
}

///|
/// Split content into lines.
fn split_content_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let chars = s.to_array()
  let current : Array[Char] = []
  for c in chars {
    if c == '\n' {
      lines.push(String::from_array(current.copy()))
      current.clear()
    } else if c != '\r' {
      current.push(c)
    }
  }
  if current.length() > 0 {
    lines.push(String::from_array(current))
  }
  lines
}
