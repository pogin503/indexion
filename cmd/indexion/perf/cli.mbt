///|
/// Show help message for performance commands.
pub fn show_help() -> Unit {
  println("indexion perf - Performance benchmark commands")
  println("")
  println("Usage:")
  println("  indexion perf kgf [options]")
  println("")
  println("Options:")
  println("  --spec=FILE        KGF spec file (default: kgfs/moonbit.kgf)")
  println(
    "  --input=FILE       Input source file (default: src/docgen/build/pipeline.mbt)",
  )
  println("  --iterations=N     Iterations per benchmark (default: 20)")
  println("  --warmup=N         Warmup iterations (default: 3)")
  println("  --help             Show this help message")
}

///|
/// Dispatch performance subcommands.
pub fn run(args : Array[String], start_idx : Int) -> Unit {
  if start_idx >= args.length() {
    show_help()
    return
  }
  let subcommand = args[start_idx]
  match subcommand {
    "kgf" => run_kgf(args, start_idx + 1)
    "help" | "--help" | "-h" => show_help()
    _ => {
      println("Unknown perf command: " + subcommand)
      println("")
      show_help()
    }
  }
}

///|
/// Run KGF parse benchmark.
fn run_kgf(args : Array[String], start_idx : Int) -> Unit {
  let mut spec_path = "kgfs/moonbit.kgf"
  let mut input_path = "src/docgen/build/pipeline.mbt"
  let mut iterations = 20
  let mut warmup = 3

  for i = start_idx; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      show_help()
      return
    } else if arg.has_prefix("--spec=") {
      spec_path = @common.get_arg_value(arg, 7)
    } else if arg.has_prefix("--input=") {
      input_path = @common.get_arg_value(arg, 8)
    } else if arg.has_prefix("--iterations=") {
      let v = @common.parse_int(@common.get_arg_value(arg, 13))
      if v > 0 { iterations = v }
    } else if arg.has_prefix("--warmup=") {
      let v = @common.parse_int(@common.get_arg_value(arg, 9))
      if v >= 0 { warmup = v }
    }
  }
  if iterations <= 0 {
    iterations = 20
  }
  if warmup < 0 {
    warmup = 3
  }

  let spec_text = @fs.read_file_to_string(spec_path) catch {
    _ => {
      println("Error: failed to read spec file: " + spec_path)
      return
    }
  }
  let source_text = @fs.read_file_to_string(input_path) catch {
    _ => {
      println("Error: failed to read input file: " + input_path)
      return
    }
  }

  let spec = match @kgf_parser.parse_kgf(spec_text) {
    Some(s) => s
    None => {
      println("Error: failed to parse spec file: " + spec_path)
      return
    }
  }
  let peg = @kgf_peg.build_peg(spec) catch {
    _ => {
      println("Error: failed to build PEG from spec")
      return
    }
  }

  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  let start_rule = spec.get_start_rule()
  let active_rules = @kgf_peg.collect_active_rules(spec)
  let tokens = lexer.tokenize(source_text)
  let file_exists = fn(path : String) -> Bool {
    @fs.is_file(path) catch {
      _ => false
    }
  }
  let language = spec.get_language()

  println("KGF benchmark")
  println("  spec      : " + spec_path)
  println("  input     : " + input_path)
  println("  language  : " + language)
  println("  tokens    : " + tokens.length().to_string())
  println("  iterations: " + iterations.to_string())
  println("  warmup    : " + warmup.to_string())
  println("")

  for _ in 0..<warmup {
    let _ = lexer.tokenize(source_text)
    let _ = tokenize_with_rebuild(spec, source_text)
    let _ = @kgf_peg.run_parse_filtered(
      peg, spec, start_rule, tokens, active_rules,
    )
    let _ = run_full_pipeline_reuse_lexer(
      spec, peg, lexer, source_text, input_path, file_exists, start_rule, active_rules,
    )
    let _ = run_full_pipeline_rebuild_lexer(
      spec, peg, source_text, input_path, file_exists, start_rule, active_rules,
    )
  }

  // Run benchmarks
  let benchmarks : Array[(String, () -> Unit)] = [
    ("tokenize_reuse_lexer", fn() { let _ = lexer.tokenize(source_text) }),
    (
      "tokenize_rebuild_lexer",
      fn() { let _ = tokenize_with_rebuild(spec, source_text) },
    ),
    (
      "parse_only",
      fn() {
        let _ = @kgf_peg.run_parse_filtered(
          peg, spec, start_rule, tokens, active_rules,
        )
      },
    ),
    (
      "full_pipeline_reuse_lexer",
      fn() {
        let _ = run_full_pipeline_reuse_lexer(
          spec, peg, lexer, source_text, input_path, file_exists, start_rule,
          active_rules,
        )
      },
    ),
    (
      "full_pipeline_rebuild_lexer",
      fn() {
        let _ = run_full_pipeline_rebuild_lexer(
          spec, peg, source_text, input_path, file_exists, start_rule,
          active_rules,
        )
      },
    ),
  ]
  for bench in benchmarks {
    let (name, task) = bench
    run_bench(name, task, iterations)
  }
}

///|
/// Run a single benchmark: execute task N times and report timing.
fn run_bench(name : String, task : () -> Unit, iterations : Int) -> Unit {
  let start = @env.now()
  for _ in 0..<iterations {
    task()
  }
  let elapsed = @common.elapsed_ms(start)
  let avg = elapsed.to_double() / iterations.to_double()
  println(
    name +
    ": " +
    elapsed.to_string() +
    "ms total, " +
    avg.to_string() +
    "ms/iter (" +
    iterations.to_string() +
    " iterations)",
  )
}

///|
/// Runs tokenize + parse + semantics once.
fn run_full_pipeline_rebuild_lexer(
  spec : @kgf_types.KGFSpec,
  peg : @kgf_peg.PEG,
  source_text : String,
  input_path : String,
  file_exists : (String) -> Bool,
  start_rule : String,
  active_rules : @hashset.HashSet[String],
) -> Int {
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  run_full_pipeline_reuse_lexer(
    spec, peg, lexer, source_text, input_path, file_exists, start_rule, active_rules,
  )
}

///|
/// Runs tokenize + parse + semantics once with a prebuilt lexer.
fn run_full_pipeline_reuse_lexer(
  spec : @kgf_types.KGFSpec,
  peg : @kgf_peg.PEG,
  lexer : @kgf_lexer.Lexer,
  source_text : String,
  input_path : String,
  file_exists : (String) -> Bool,
  start_rule : String,
  active_rules : @hashset.HashSet[String],
) -> Int {
  let graph = @graph.CodeGraph::new()
  let tokens = lexer.tokenize(source_text)
  match
    @kgf_peg.run_parse_filtered(peg, spec, start_rule, tokens, active_rules) {
    Some(eval_result) => {
      let ctx = @kgf_semantics.SemEvalCtx::new(
        spec,
        graph,
        input_path,
        "",
        spec.get_language(),
        file_exists,
      )
      for event in eval_result.get_events() {
        @kgf_semantics.eval_rule_semantics(event.0, event.1, ctx)
      }
      graph.get_edges().length()
    }
    None => 0
  }
}

///|
/// Tokenizes once while rebuilding lexer to measure construction overhead.
fn tokenize_with_rebuild(
  spec : @kgf_types.KGFSpec,
  source_text : String,
) -> Int {
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  lexer.tokenize(source_text).length()
}

///|
/// Parses an integer, returning a fallback on error.
fn parse_int(text : String, fallback : Int) -> Int {
  if text.length() == 0 {
    return fallback
  }
  let chars = text.to_array()
  let mut value = 0
  for c in chars {
    if c < '0' || c > '9' {
      return fallback
    }
    value = value * 10 + (c.to_int() - '0'.to_int())
  }
  if value < 0 {
    fallback
  } else {
    value
  }
}

