///|
/// # indexion kgf
///
/// KGF (Knowledge Graph Framework) inspection tools.
///
/// ## Overview
///
/// Debug and inspect KGF spec parsing. Useful for developing and testing
/// new language specifications.
///
/// ## Usage
///
/// ```bash
/// indexion kgf <subcommand> [options]
/// ```
///
/// ## Subcommands
///
/// | Subcommand | Description |
/// |------------|-------------|
/// | `inspect` | Inspect parsing of a file with a KGF spec |
/// | `tokens` | Show tokenization result only |
/// | `events` | Show parse events only |
/// | `edges` | Show generated edges only |
///
/// ## Examples
///
/// ```bash
/// # Full inspection of a file
/// indexion kgf inspect fixtures/project/cargo/Cargo.toml
///
/// # Show only tokens
/// indexion kgf tokens fixtures/project/go/go.mod
///
/// # Specify spec explicitly
/// indexion kgf inspect --spec=cargo-toml Cargo.toml
/// ```

///|
/// CLI configuration.
priv struct KgfConfig {
  mut subcommand : String
  mut file_path : String
  mut spec_name : String // empty means auto-detect
  mut kgf_dir : String
  show_tokens : Bool
  show_events : Bool
  show_edges : Bool
}

///|
fn KgfConfig::default() -> KgfConfig {
  {
    subcommand: "inspect",
    file_path: "",
    spec_name: "",
    kgf_dir: "kgfs",
    show_tokens: true,
    show_events: true,
    show_edges: true,
  }
}

///|
/// Create KgfConfig from argparse Matches.
fn KgfConfig::from_matches(matches : @argparse.Matches) -> KgfConfig {
  let mut config = KgfConfig::default()
  // Global options
  match matches.values.get("spec") {
    Some(vals) =>
      if vals.length() > 0 && vals[0].length() > 0 {
        config.spec_name = vals[0]
      }
    None => ()
  }
  match matches.values.get("kgf-dir") {
    Some(vals) => if vals.length() > 0 { config.kgf_dir = vals[0] }
    None => ()
  }
  // Subcommand dispatch
  match matches.subcommand {
    Some((name, sub_matches)) => {
      config.subcommand = name
      match name {
        "add" =>
          match sub_matches.values.get("spec-name") {
            Some(vals) => if vals.length() > 0 { config.file_path = vals[0] }
            None => ()
          }
        "inspect" | "tokens" | "events" | "edges" => {
          match sub_matches.values.get("file") {
            Some(vals) => if vals.length() > 0 { config.file_path = vals[0] }
            None => ()
          }
          match name {
            "tokens" =>
              config = { ..config, show_events: false, show_edges: false }
            "events" =>
              config = { ..config, show_tokens: false, show_edges: false }
            "edges" =>
              config = { ..config, show_tokens: false, show_events: false }
            _ => ()
          }
        }
        _ => ()
      }
    }
    None => ()
  }
  config
}

///|
/// Define the kgf command for argparse.
pub fn command() -> @argparse.Command {
  let global_options : Array[@argparse.OptionArg] = [
    @argparse.OptionArg(
      "spec",
      about="Specify KGF spec name (auto-detect if omitted)",
      default_values=[""],
      global=true,
    ),
    @argparse.OptionArg(
      "kgf-dir",
      about="KGF specs directory",
      default_values=["kgfs"],
      global=true,
    ),
  ]
  let file_positional : Array[@argparse.PositionArg] = [
    @argparse.PositionArg(
      "file",
      about="File to inspect",
      num_args=@argparse.ValueRange::single(),
    ),
  ]
  @argparse.Command(
    "kgf",
    about="KGF spec management and inspection",
    options=global_options[:],
    subcommand_required=true,
    arg_required_else_help=true,
    subcommands=[
      @argparse.Command("list", about="List installed KGF specs"),
      @argparse.Command("update", about="Update all specs from GitHub"),
      @argparse.Command("add", about="Download and install a single spec", positionals=[
        @argparse.PositionArg(
          "spec-name",
          about="Name of the spec to add",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      @argparse.Command(
        "inspect",
        about="Full inspection (tokens, events, edges)",
        positionals=file_positional[:],
      ),
      @argparse.Command(
        "tokens",
        about="Show tokenization only",
        positionals=file_positional[:],
      ),
      @argparse.Command(
        "events",
        about="Show parse events only",
        positionals=file_positional[:],
      ),
      @argparse.Command(
        "edges",
        about="Show generated edges only",
        positionals=file_positional[:],
      ),
    ],
  )
}

///|
/// Entry point for the kgf subcommand using argparse Matches.
pub async fn run_matches(matches : @argparse.Matches) -> Unit {
  let config = KgfConfig::from_matches(matches)
  match config.subcommand {
    "list" => run_list()
    "update" => run_kgf_update()
    "add" => {
      if config.file_path.length() == 0 {
        println("Error: Spec name required")
        println("")
        println("Usage: indexion kgf add <spec-name>")
        return
      }
      run_kgf_add(config.file_path)
    }
    "inspect" | "tokens" | "events" | "edges" => {
      if config.file_path.length() == 0 {
        println("Error: No file specified")
        println("")
        println(command().render_help())
        return
      }
      match config.subcommand {
        "inspect" => run_inspect(config)
        "tokens" => run_tokens(config)
        "events" => run_events(config)
        "edges" => run_edges(config)
        _ => ()
      }
    }
    _ => {
      println("Unknown subcommand: \{config.subcommand}")
      println(command().render_help())
    }
  }
}

///|
/// List installed KGF specs.
fn run_list() -> Unit {
  let specs = @kgf_manage.list_installed_specs()
  if specs.length() == 0 {
    println("No KGF specs installed.")
    match @kgf_manage.get_installed_kgfs_dir() {
      Some(dir) => println("Searched: " + dir)
      None => println("No kgfs directory found.")
    }
    return
  }
  // Print table header
  println(pad_right("Category", 14) + pad_right("Name", 22) + "Sources")
  println(
    pad_right("─".repeat(12), 14) +
    pad_right("─".repeat(20), 22) +
    "─".repeat(20),
  )
  for spec in specs {
    let sources = if spec.sources.length() > 0 {
      spec.sources.join(", ")
    } else {
      "(none)"
    }
    let category = if spec.category.length() > 0 {
      spec.category
    } else {
      "(root)"
    }
    println(pad_right(category, 14) + pad_right(spec.name, 22) + sources)
  }
  println("")
  println("Total: \{specs.length()} specs")
}

///|
/// Update KGF specs from GitHub.
async fn run_kgf_update() -> Unit {
  @kgf_manage.update_kgfs() catch {
    err => {
      println("Error: " + err.to_string())
      return
    }
  }
}

///|
/// Add a single KGF spec from GitHub.
async fn run_kgf_add(spec_name : String) -> Unit {
  @kgf_manage.add_kgf(spec_name) catch {
    err => {
      println("Error: " + err.to_string())
      return
    }
  }
}

///|
/// Pad string to the right with spaces.
fn pad_right(s : String, width : Int) -> String {
  if s.length() >= width {
    return s
  }
  let buf = StringBuilder::new()
  buf.write_string(s)
  for i = s.length(); i < width; i = i + 1 {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Run full inspection.
fn run_inspect(config : KgfConfig) -> Unit {
  println("=== indexion kgf inspect ===")
  println("File: \{config.file_path}")
  println("")
  let registry = @registry.KGFRegistry::load_from_dir(config.kgf_dir)
  let spec_name = if config.spec_name.length() > 0 {
    config.spec_name
  } else {
    match registry.detect_from_path(config.file_path) {
      Some(name) => name
      None => {
        println("Error: Cannot detect language for file")
        println("Use --spec=<name> to specify explicitly")
        return
      }
    }
  }
  println("Detected spec: \{spec_name}")
  let spec = match registry.get_spec(spec_name) {
    Some(s) => s
    None => {
      println("Error: Spec '\{spec_name}' not found")
      return
    }
  }
  let source = @fs.read_file_to_string(config.file_path) catch {
    err => {
      println("Error reading file: \{err}")
      return
    }
  }
  // Ensure trailing newline
  let source = if source.has_suffix("\n") { source } else { source + "\n" }
  println("Source length: \{source.length()} chars")
  println("")
  // Tokenize
  println("=== Tokens ===")
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let tokens = lexer.tokenize(source)
  println("Token count: \{tokens.length()}")
  if config.show_tokens {
    for i, tok in tokens {
      if i < 50 {
        println("  [\{i}] \{tok.kind}: \"\{escape_string(tok.text)}\"")
      } else if i == 50 {
        println("  ... (\{tokens.length() - 50} more tokens)")
      }
    }
  }
  println("")
  // Parse
  println("=== Parse ===")
  let peg = @peg.build_peg(spec) catch {
    err => {
      println("Error building PEG: \{err}")
      return
    }
  }
  let start_rule = spec.get_start_rule()
  println("Start rule: \{start_rule}")
  let parse_result = @peg.run_parse(peg, spec, start_rule, tokens)
  match parse_result {
    Some(eval_result) => {
      let events = eval_result.get_events()
      println("Parse: SUCCESS")
      println("Event count: \{events.length()}")
      if config.show_events {
        println("")
        println("=== Events ===")
        for i, event in events {
          let rule_name = event.0
          let labels = event.1
          if i < 100 {
            let labels_str = format_labels(labels)
            println("  [\{i}] \{rule_name} \{labels_str}")
          } else if i == 100 {
            println("  ... (\{events.length() - 100} more events)")
          }
        }
      }
      // Evaluate semantics
      println("")
      println("=== Semantics ===")
      let graph = @graph.CodeGraph::new()
      let _ = graph.get_or_add_module(
        config.file_path,
        file=Some(config.file_path),
      )
      let ctx = @semantics.SemEvalCtx::new(
        spec,
        graph,
        config.file_path,
        "",
        spec.get_language(),
        fn(_path) { false },
      )
      for event in events {
        let rule_name = event.0
        let labels = event.1
        @semantics.eval_rule_semantics(rule_name, labels, ctx)
      }
      let edges = graph.get_edges()
      println("Edge count: \{edges.length()}")
      if config.show_edges {
        println("")
        println("=== Edges ===")
        for edge in edges {
          let attrs_str = format_attrs(edge.attrs)
          println(
            "  \{edge.kind.to_string()}: \{edge.from} -> \{edge.to}\{attrs_str}",
          )
        }
      }
    }
    None => {
      println("Parse: FAILED")
      println("")
      println("Possible issues:")
      println("  - Grammar doesn't match file structure")
      println("  - Missing tokens or rules")
      println("  - File format issues")
    }
  }
}

///|
/// Run tokens-only inspection.
fn run_tokens(config : KgfConfig) -> Unit {
  let c = { ..config, show_events: false, show_edges: false }
  run_inspect(c)
}

///|
/// Run events-only inspection.
fn run_events(config : KgfConfig) -> Unit {
  let c = { ..config, show_tokens: false, show_edges: false }
  run_inspect(c)
}

///|
/// Run edges-only inspection.
fn run_edges(config : KgfConfig) -> Unit {
  let c = { ..config, show_tokens: false, show_events: false }
  run_inspect(c)
}

///|
/// Format labels map for display.
fn format_labels(labels : Map[String, Json]) -> String {
  if labels.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for entry in labels {
    let k = entry.0
    let v = entry.1
    let v_str = match v {
      String(s) => "\"" + escape_string(s) + "\""
      Number(n, ..) => n.to_string()
      True => "true"
      False => "false"
      Null => "null"
      _ => v.stringify()
    }
    parts.push("\{k}=\{v_str}")
  }
  "{ " + parts.join(", ") + " }"
}

///|
/// Format edge attrs for display.
fn format_attrs(attrs : Map[String, String]) -> String {
  if attrs.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for entry in attrs {
    parts.push("\{entry.0}=\"\{entry.1}\"")
  }
  " [" + parts.join(", ") + "]"
}

///|
/// Escape string for display.
fn escape_string(s : String) -> String {
  let chars = s.to_array()
  let result : Array[Char] = []
  for c in chars {
    match c {
      '\n' => {
        result.push('\\')
        result.push('n')
      }
      '\r' => {
        result.push('\\')
        result.push('r')
      }
      '\t' => {
        result.push('\\')
        result.push('t')
      }
      '\\' => {
        result.push('\\')
        result.push('\\')
      }
      '"' => {
        result.push('\\')
        result.push('"')
      }
      _ => result.push(c)
    }
  }
  String::from_array(result)
}
