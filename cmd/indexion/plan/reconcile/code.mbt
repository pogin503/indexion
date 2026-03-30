///|
fn default_document_symbol_kinds() -> Map[String, Bool] {
  let kinds : Map[String, Bool] = {}
  for
    kind in [
      "function", "type", "struct", "enum", "trait", "class", "interface", "module",
    ] {
    kinds.set(kind, true)
  }
  kinds
}

///|
fn discovery_roots(target_dir : String) -> Array[String] {
  if target_dir != "." {
    return [target_dir]
  }
  let entries = @fs.read_dir(target_dir) catch { _ => return [target_dir] }
  let roots : Array[String] = []
  for entry in entries {
    if entry != "." && entry != ".." {
      roots.push(entry)
    }
  }
  if roots.length() == 0 {
    [target_dir]
  } else {
    roots
  }
}

///|
/// Fast code unit extraction using KGF lexer only (no PEG parse).
/// ~10x faster than graph-based extraction for large projects.
fn build_code_units_fast(
  discovered_paths : Array[String],
  registry : @registry.KGFRegistry,
) -> Array[CodeUnit] {
  let units : Array[CodeUnit] = []
  let symbol_kinds = default_document_symbol_kinds()
  for path in discovered_paths {
    // Only process files the registry recognizes
    let lang = match registry.detect_from_path(path) {
      Some(l) => l
      None => continue
    }
    let spec = match registry.get_spec(lang) {
      Some(s) => s
      None => continue
    }
    let content = @fs.read_file_to_string(path) catch { _ => continue }
    // Use KGF lexer to extract pub declarations (no PEG needed)
    let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
    let tokens = lexer.tokenize(content)
    let functions = @kgf_features.extract_functions(tokens, path)
    let pub_decls = @kgf_features.extract_pub_declarations(
      content,
      path,
      Some(registry),
    )
    // Extract doc comments via KGF tokens (language-agnostic)
    let line_docs = @kgf_features.extract_doc_map(tokens)
    // Module ID from path (dirname-based)
    let module_id = path
    // Build code units from pub declarations
    for decl in pub_decls {
      let kind = decl.kind
      if not(symbol_kinds.contains(kind)) {
        continue
      }
      let symbol_id = path + "::" + decl.name
      let inline_doc = line_docs.get(decl.line)
      let code_hash = make_hash([
        symbol_id,
        decl.name,
        kind,
        "",
        module_id,
        inline_doc.unwrap_or(""),
      ])
      units.push({
        symbol_id,
        name: decl.name,
        kind,
        ns: "",
        module_id,
        module_path: path,
        inline_doc,
        code_hash,
      })
    }
    // Also include functions (which may not have pub prefix in some languages)
    for func in functions {
      let symbol_id = path + "::" + func.get_name()
      // Skip if already added from pub_decls
      let mut exists = false
      for u in units {
        if u.symbol_id == symbol_id {
          exists = true
          break
        }
      }
      if exists {
        continue
      }
      // Only include if it matches document_symbol_kinds
      if not(symbol_kinds.contains("function")) {
        continue
      }
      let code_hash = make_hash([
        symbol_id,
        func.get_name(),
        "function",
        "",
        module_id,
        "",
      ])
      units.push({
        symbol_id,
        name: func.get_name(),
        kind: "function",
        ns: "",
        module_id,
        module_path: path,
        inline_doc: None,
        code_hash,
      })
    }
  }
  units.sort_by(fn(a, b) { a.symbol_id.compare(b.symbol_id) })
  units
}
