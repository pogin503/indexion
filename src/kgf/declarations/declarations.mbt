///|
pub struct PubDeclaration {
  kind : String
  name : String
  line : Int
  category : String
}

///|
fn preprocess_content(content : String, spec : @kgf_types.KGFSpec) -> String {
  match spec.get_preprocess() {
    Some(steps) =>
      @kgf_preprocess.apply_preprocess(
        content,
        Some(steps),
        spec.get_preprocess_fst(),
      ) catch {
        _ => panic()
      }
    None => content
  }
}

///|
fn to_lower_str(s : String) -> String {
  let chars = s.to_array()
  let result : Array[Char] = []
  for c in chars {
    let code = c.to_int()
    if code >= 0x41 && code <= 0x5A {
      result.push((code + 32).unsafe_to_char())
    } else {
      result.push(c)
    }
  }
  String::from_array(result)
}

///|
pub fn tokenize_source(
  content : String,
  path : String,
  registry : @kgf_registry.KGFRegistry?,
) -> Array[@kgf_types.Tok]? {
  let reg = match registry {
    Some(r) => r
    None => return None
  }
  let lang = match reg.detect_from_path(path) {
    Some(l) => l
    None => return None
  }
  let spec = match reg.get_spec(lang) {
    Some(s) => s
    None => return None
  }
  let prepared = preprocess_content(content, spec)
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  Some(lexer.tokenize(prepared))
}

///|
fn is_doc_token_kind(kind : String) -> Bool {
  kind.has_prefix("Doc")
}

///|
pub fn extract_doc_map(tokens : Array[@kgf_types.Tok]) -> Map[Int, String] {
  let result : Map[Int, String] = {}
  let token_lines : Array[Int] = Array::make(tokens.length(), 1)
  let mut line = 1
  for i, tok in tokens {
    token_lines[i] = line
    if tok.get_kind() == "NL" {
      line += 1
    }
  }
  let mut i = 0
  while i < tokens.length() {
    let kind = tokens[i].get_kind()
    if is_doc_token_kind(kind) {
      let doc_buf = StringBuilder::new()
      let mut first = true
      while i < tokens.length() {
        let k = tokens[i].get_kind()
        if is_doc_token_kind(k) {
          let value = tokens[i].get_value()
          if value.length() > 0 {
            if !first {
              doc_buf.write_string("\n")
            }
            doc_buf.write_string(value)
            first = false
          }
          i += 1
        } else if k == "NL" || k == "SKIP" || k == "WS" {
          i += 1
        } else {
          break
        }
      }
      let doc = doc_buf.to_string()
      if doc.length() > 0 && i < tokens.length() {
        let target_line = if i < token_lines.length() {
          token_lines[i]
        } else {
          line
        }
        result.set(target_line, doc)
      }
    } else {
      i += 1
    }
  }
  result
}

///|
pub fn extract_doc_map_from_source(
  content : String,
  path : String,
  registry : @kgf_registry.KGFRegistry?,
) -> Map[Int, String] {
  match tokenize_source(content, path, registry) {
    Some(tokens) => extract_doc_map(tokens)
    None => {}
  }
}

///|
pub fn extract_pub_declarations_and_doc_map(
  content : String,
  path : String,
  registry : @kgf_registry.KGFRegistry?,
) -> (Array[PubDeclaration], Map[Int, String]) {
  let reg = match registry {
    Some(r) => r
    None => return ([], {})
  }
  let lang = match reg.detect_from_path(path) {
    Some(l) => l
    None => return ([], {})
  }
  let spec = match reg.get_spec(lang) {
    Some(s) => s
    None => return ([], {})
  }
  let prepared = preprocess_content(content, spec)
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  let tokens = lexer.tokenize(prepared)
  let peg = @kgf_peg.build_peg(spec) catch { _ => return ([], {}) }
  let start_rule = spec.get_start_rule()
  let parse_result = match @kgf_peg.run_parse(peg, spec, start_rule, tokens) {
    Some(r) => r
    None => return ([], {})
  }
  let graph = @graph.CodeGraph::new()
  let _ = graph.get_or_add_module(path, file=Some(path))
  let ctx = @kgf_semantics.SemEvalCtx::new(
    spec,
    graph,
    path,
    "",
    spec.get_language(),
    fn(_) { false },
  )
  for event in parse_result.get_events() {
    @kgf_semantics.eval_rule_semantics(event.0, event.1, ctx)
  }
  let declarations : Array[PubDeclaration] = []
  let doc_map : Map[Int, String] = {}
  let function_kinds : Array[String] = match
    spec.get_feature("function_kinds") {
    Some(kinds) => kinds
    None => []
  }
  let line_offsets = build_line_offsets(prepared)
  for edge in graph.get_edges() {
    if !(edge.kind is @graph.Declares) {
      continue
    }
    let name = edge.attrs.get("name").unwrap_or("")
    let kind = edge.attrs.get("kind").unwrap_or("")
    let doc = edge.attrs.get("doc").unwrap_or("")
    let normalized = to_lower_str(kind)
    let category = if contains_str(function_kinds, kind) {
      "function"
    } else {
      "type"
    }
    let line = estimate_declaration_line(prepared, name, line_offsets)
    declarations.push({ kind: normalized, name, line, category })
    if doc.length() > 0 {
      doc_map.set(line, doc)
    }
  }
  (declarations, doc_map)
}

///|
pub fn count_pub_declarations(
  content : String,
  path : String,
  registry : @kgf_registry.KGFRegistry?,
) -> Int {
  let (decls, _) = extract_pub_declarations_and_doc_map(content, path, registry)
  decls.length()
}

///|
fn build_line_offsets(content : String) -> Array[Int] {
  let offsets : Array[Int] = [0]
  for i, c in content {
    if c == '\n' {
      offsets.push(i + 1)
    }
  }
  offsets
}

///|
fn estimate_declaration_line(
  content : String,
  name : String,
  line_offsets : Array[Int],
) -> Int {
  if name.length() == 0 {
    return 1
  }
  let content_chars = content.to_array()
  let name_chars = name.to_array()
  let content_len = content_chars.length()
  let name_len = name_chars.length()
  for i = 0; i < content_len - name_len + 1; i = i + 1 {
    let mut matched = true
    for j = 0; j < name_len; j = j + 1 {
      if content_chars[i + j] != name_chars[j] {
        matched = false
        break
      }
    }
    if matched {
      for line = line_offsets.length() - 1; line >= 0; line = line - 1 {
        if i >= line_offsets[line] {
          return line + 1
        }
      }
    }
  }
  1
}

///|
fn contains_str(arr : Array[String], value : String) -> Bool {
  for item in arr {
    if item == value {
      return true
    }
  }
  false
}
