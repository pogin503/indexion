///|
/// # indexion doc graph
///
/// Generate dependency graph in Mermaid format from source files.
///
/// ## Usage
///
/// ```bash
/// indexion doc graph [options] [files...]
/// ```
///
/// ## Options
///
/// | Option | Description | Default |
/// |--------|-------------|---------|
/// | `--output=FILE` | Output file (- for stdout) | - |
/// | `--specs=DIR` | KGF specs directory | kgfs |
/// | `--title=TEXT` | Diagram title | Module Dependencies |
/// | `--format=FORMAT` | Output format: mermaid, json | mermaid |
///
/// ## Examples
///
/// ```bash
/// # Output to stdout
/// indexion doc graph src/
///
/// # Save to file
/// indexion doc graph --output=deps.md src/
///
/// # With custom title
/// indexion doc graph --title="My Project Dependencies" src/
/// ```

///|
/// CLI configuration for graph command.
pub struct GraphConfig {
  output : String
  specs_dir : String
  title : String
  format : String
  input_paths : Array[String]
  show_help : Bool
}

///|
/// Create default configuration.
pub fn GraphConfig::default() -> GraphConfig {
  {
    output: "-",
    specs_dir: "kgfs",
    title: "Module Dependencies",
    format: "mermaid",
    input_paths: [],
    show_help: false,
  }
}

///|
/// Extract value after '=' in argument.
fn get_arg_value(arg : String, start : Int) -> String {
  let chars = arg.to_array()
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
/// Parse command line arguments.
pub fn parse_args(args : Array[String], start_idx : Int) -> GraphConfig {
  let mut config = GraphConfig::default()
  let paths : Array[String] = []
  for i = start_idx; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      config = { ..config, show_help: true }
    } else if arg.has_prefix("--output=") {
      let value = get_arg_value(arg, 9)
      config = { ..config, output: value }
    } else if arg.has_prefix("--specs=") {
      let value = get_arg_value(arg, 8)
      config = { ..config, specs_dir: value }
    } else if arg.has_prefix("--title=") {
      let value = get_arg_value(arg, 8)
      config = { ..config, title: value }
    } else if arg.has_prefix("--format=") {
      let value = get_arg_value(arg, 9)
      config = { ..config, format: value }
    } else if not(arg.has_prefix("-")) {
      paths.push(arg)
    }
  }
  { ..config, input_paths: paths }
}

///|
/// Show help message.
pub fn show_help() -> Unit {
  println("indexion doc graph - Generate dependency graph in Mermaid format")
  println("")
  println("Usage:")
  println("  indexion doc graph [options] [files...]")
  println("")
  println("Options:")
  println("  --output=FILE    Output file (- for stdout, default: -)")
  println("  --specs=DIR      KGF specs directory (default: kgfs)")
  println("  --title=TEXT     Diagram title (default: Module Dependencies)")
  println("  --format=FORMAT  Output format: mermaid, json (default: mermaid)")
  println("  --help           Show this help message")
  println("")
  println("Examples:")
  println("  indexion doc graph src/")
  println("  indexion doc graph --output=deps.md src/")
  println("  indexion doc graph --title=\"API Dependencies\" src/api/")
}

///|
/// Load KGF specs from directory and build registry.
fn load_registry(specs_dir : String) -> @registry.KGFRegistry {
  @registry.KGFRegistry::load_from_dir(specs_dir)
}

///|
/// Load KGF specs from directory as Map (for DocConfig compatibility).
fn load_specs(specs_dir : String) -> Map[String, @kgf_types.KGFSpec] {
  let specs : Map[String, @kgf_types.KGFSpec] = {}
  try {
    if not(@fs.is_dir(specs_dir)) {
      return specs
    }
    let entries = @fs.read_dir(specs_dir)
    for entry in entries {
      if entry.has_suffix(".kgf") {
        let path = specs_dir + "/" + entry
        let content = @fs.read_file_to_string(path)
        match @parser.parse_kgf(content) {
          Some(spec) => {
            let lang = spec.get_language()
            specs.set(lang, spec)
          }
          None => ()
        }
      }
    }
  } catch {
    _ => ()
  }
  specs
}

///|
/// Collect files from path using KGF registry for file detection.
fn collect_files(
  path : String,
  files : Array[(String, String)],
  registry : @registry.KGFRegistry,
) -> Unit {
  let clean_path = trim_trailing_slash(path)
  try {
    if @fs.is_dir(clean_path) {
      let entries = @fs.read_dir(clean_path)
      for entry in entries {
        // Skip build directories and mooncakes
        if entry == "_build" || entry == ".mooncakes" || entry == "target" {
          continue
        }
        let full_path = clean_path + "/" + entry
        collect_files(full_path, files, registry)
      }
    } else if @fs.is_file(clean_path) {
      if registry.is_file_supported(clean_path) {
        let content = @fs.read_file_to_string(clean_path)
        files.push((clean_path, content))
      }
    }
  } catch {
    _ => ()
  }
}

///|
/// Trim trailing slash.
fn trim_trailing_slash(path : String) -> String {
  if path.length() > 0 && path.has_suffix("/") {
    let chars = path.to_array()
    let result : Array[Char] = []
    for i = 0; i < chars.length() - 1; i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    path
  }
}

///|
/// Write output to file or stdout.
fn write_output(output : String, content : String) -> Unit {
  if output == "-" {
    println(content)
  } else {
    try {
      @fs.write_string_to_file(output, content)
      println("Written to: " + output)
    } catch {
      e => println("Error writing file: " + e.to_string())
    }
  }
}

///|
/// Generate JSON output with dependencies and circular references.
fn generate_json_output(
  deps : Array[@query.ModuleDep],
  circulars : Array[@query.CircularDep],
) -> String {
  let obj : Map[String, Json] = {}
  // Add dependencies
  let deps_arr : Array[Json] = []
  for dep in deps {
    let dep_obj : Map[String, Json] = {}
    dep_obj.set("from", dep.from.to_json())
    dep_obj.set("to", dep.to.to_json())
    match dep.via {
      Some(v) => dep_obj.set("via", v.to_json())
      None => ()
    }
    match dep.dep_kind {
      Some(k) => dep_obj.set("kind", k.to_json())
      None => ()
    }
    deps_arr.push(Json::object(dep_obj))
  }
  obj.set("dependencies", Json::array(deps_arr))
  // Add circular references
  let circ_arr : Array[Json] = []
  for circ in circulars {
    let circ_obj : Map[String, Json] = {}
    circ_obj.set("from", circ.from.to_json())
    circ_obj.set("to", circ.to.to_json())
    circ_arr.push(Json::object(circ_obj))
  }
  obj.set("circular_dependencies", Json::array(circ_arr))
  // Add statistics
  let stats : Map[String, Json] = {}
  stats.set("total_dependencies", deps.length().to_json())
  stats.set("circular_count", circulars.length().to_json())
  obj.set("statistics", Json::object(stats))
  Json::object(obj).stringify()
}

///|
/// Run the graph command.
pub fn run(args : Array[String], start_idx : Int) -> Unit {
  let config = parse_args(args, start_idx)
  if config.show_help {
    show_help()
    return
  }
  // Load registry and specs
  let registry = load_registry(config.specs_dir)
  let specs = load_specs(config.specs_dir)
  // Collect files using registry-based detection
  let files : Array[(String, String)] = []
  if config.input_paths.length() > 0 {
    for path in config.input_paths {
      collect_files(path, files, registry)
    }
  }
  if files.length() == 0 {
    println("No input files found.")
    return
  }
  // Build graph using KGF pipeline
  let doc_config = @build.DocConfig::new(
    files,
    specs,
    options=@render.RenderOptions::new(format=@render.OutputFormat::json()),
  )
  let (_, graph) = @build.build_with_graph(doc_config)
  // Extract dependencies and circular references
  let deps = @query.extract_module_deps(graph)
  let circulars = @query.extract_circular_deps(graph)
  // Generate output based on format
  let output = if config.format == "json" {
    generate_json_output(deps, circulars)
  } else {
    // Default to Mermaid with external dependency detection from KGF
    let external_prefixes = registry.get_external_prefixes()
    let internal_prefixes = registry.get_internal_prefixes()
    @diagram.generate_dep_diagram_with_externals(
      deps,
      circulars,
      external_prefixes,
      internal_prefixes~,
      title=config.title,
    )
  }
  // Handle empty graph case
  if output.length() == 0 {
    if config.format == "json" {
      write_output(
        config.output,
        "{\"dependencies\":[],\"circular_dependencies\":[],\"statistics\":{\"total_dependencies\":0,\"circular_count\":0}}",
      )
    } else {
      println("No dependencies found in the analyzed files.")
    }
    return
  }
  write_output(config.output, output)
  // Print summary to stderr if outputting to file
  if config.output != "-" {
    println("Dependencies: " + deps.length().to_string())
    if circulars.length() > 0 {
      println("Circular references: " + circulars.length().to_string())
    }
  }
}
