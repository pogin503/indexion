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
fn document_symbol_kinds_for_path(
  path : String,
  registry : @registry.KGFRegistry,
) -> Map[String, Bool] {
  let fallback = default_document_symbol_kinds()
  match registry.detect_from_path(path) {
    Some(lang) =>
      match registry.get_spec(lang) {
        Some(spec) =>
          match spec.get_feature("document_symbol_kinds") {
            Some(values) => {
              let configured : Map[String, Bool] = {}
              for value in values {
                let normalized = lower_string(@common.trim_ascii_spaces(value))
                if normalized.length() > 0 {
                  configured.set(normalized, true)
                }
              }
              if configured.is_empty() {
                fallback
              } else {
                configured
              }
            }
            None => fallback
          }
        None => fallback
      }
    None => fallback
  }
}

///|
fn should_include_symbol(
  kind : String,
  module_path : String,
  registry : @registry.KGFRegistry,
) -> Bool {
  document_symbol_kinds_for_path(module_path, registry).contains(
    lower_string(kind),
  )
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
fn build_code_graph(
  target_dir : String,
  specs_dir : String,
) -> (@registry.KGFRegistry, Array[String], @graph.CodeGraph) {
  let registry = @registry.KGFRegistry::load_from_dir(specs_dir)
  let kgf_ignore = registry.collect_ignore_patterns()
  let discover_opts = @pipeline.DiscoverOptions::new(
    kgf_ignore~,
    root_dir=target_dir,
  )
  let discovered_paths = @pipeline.discover_files(
    discovery_roots(target_dir),
    discover_opts,
  )
  let files = @pipeline.collect_supported_files(discovered_paths, registry)
  let specs = registry.to_specs_map()
  let config = @doc_build.DocConfig::new(files, specs, root_path=target_dir)
  let (_output, graph) = @doc_build.build_with_graph(config)
  (registry, discovered_paths, graph)
}

///|
fn extract_code_units(
  graph : @graph.CodeGraph,
  registry : @registry.KGFRegistry,
) -> Array[CodeUnit] {
  let units : Array[CodeUnit] = []
  for entry in graph.get_symbols() {
    let symbol = entry.1
    let module_path = match graph.get_module(symbol.module_id) {
      Some(module_node) =>
        match module_node.file {
          Some(file) => file
          None => symbol.module_id
        }
      None => symbol.module_id
    }
    if not(should_include_symbol(symbol.kind, module_path, registry)) {
      continue
    }
    let code_hash = make_hash([
      symbol.id,
      symbol.name,
      symbol.kind,
      symbol.ns,
      module_path,
      match symbol.doc {
        Some(doc) => doc
        None => ""
      },
    ])
    units.push({
      symbol_id: symbol.id,
      name: symbol.name,
      kind: symbol.kind,
      ns: symbol.ns,
      module_id: symbol.module_id,
      module_path,
      inline_doc: symbol.doc,
      code_hash,
    })
  }
  units.sort_by(fn(a, b) { a.symbol_id.compare(b.symbol_id) })
  units
}
