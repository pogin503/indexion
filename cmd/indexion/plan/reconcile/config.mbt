///|
pub fn parse_args(args : Array[String], start_idx : Int) -> ReconcileConfig {
  let mut config = ReconcileConfig::default()
  for i = start_idx; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      config = { ..config, show_help: true }
    } else if arg.has_prefix("--output=") || arg.has_prefix("-o=") {
      let prefix_len = if arg.has_prefix("--output=") { 9 } else { 3 }
      config = { ..config, output: get_arg_value(arg, prefix_len) }
    } else if arg.has_prefix("--format=") {
      config = { ..config, format: get_arg_value(arg, 9) }
    } else if arg.has_prefix("--specs=") || arg.has_prefix("--specs-dir=") {
      let prefix_len = if arg.has_prefix("--specs-dir=") { 12 } else { 8 }
      config = { ..config, specs_dir: get_arg_value(arg, prefix_len) }
    } else if arg.has_prefix("--index-dir=") {
      config = { ..config, index_dir: get_arg_value(arg, 12) }
    } else if arg.has_prefix("--config=") {
      config = { ..config, config_path: get_arg_value(arg, 9) }
    } else if arg.has_prefix("--review-results=") {
      config = { ..config, review_results_path: get_arg_value(arg, 17) }
    } else if arg.has_prefix("--threshold-seconds=") {
      config = {
        ..config,
        threshold_seconds: parse_int(get_arg_value(arg, 20)),
      }
    } else if arg.has_prefix("--max-candidates=") {
      config = { ..config, max_candidates: parse_int(get_arg_value(arg, 17)) }
    } else if arg.has_prefix("--doc=") {
      let new_doc_paths = config.doc_paths.copy()
      new_doc_paths.push(get_arg_value(arg, 6))
      config = { ..config, doc_paths: new_doc_paths }
    } else if arg.has_prefix("--doc-spec=") {
      let new_doc_specs = config.doc_specs.copy()
      new_doc_specs.push(get_arg_value(arg, 11))
      config = { ..config, doc_specs: new_doc_specs }
    } else if arg == "--no-file-fallback" {
      config = { ..config, allow_file_fallback: false }
    } else if arg == "--mtime-only" {
      config = { ..config, git_preferred: false, mtime_fallback: true }
    } else if arg == "--logical-review=off" {
      config = { ..config, logical_review_mode: "off" }
    } else if arg == "--logical-review=queue" {
      config = { ..config, logical_review_mode: "queue" }
    } else if not(arg.has_prefix("-")) && config.target_dir.length() == 0 {
      config = { ..config, target_dir: arg }
    }
  }
  config
}

///|
fn resolve_specs_dir(target_dir : String, specs_dir? : String = "") -> String {
  @config_paths.resolve_reconcile_specs_dir(
    target_dir,
    explicit_specs_dir=specs_dir,
  )
}

///|
fn apply_file_config(
  config : ReconcileConfig,
  file_config : @config_paths.ReconcileFileConfig,
) -> ReconcileConfig {
  let mut updated = config
  match file_config.doc_paths {
    Some(values) => updated = { ..updated, doc_paths: values }
    None => ()
  }
  match file_config.doc_specs {
    Some(values) => updated = { ..updated, doc_specs: values }
    None => ()
  }
  match file_config.index_dir {
    Some(value) => updated = { ..updated, index_dir: value }
    None => ()
  }
  match file_config.review_results_path {
    Some(value) =>
      if updated.review_results_path.length() == 0 {
        updated = { ..updated, review_results_path: value }
      }
    None => ()
  }
  match file_config.format {
    Some(value) =>
      if config.format == "json" {
        updated = { ..updated, format: value }
      }
    None => ()
  }
  match file_config.threshold_seconds {
    Some(value) => updated = { ..updated, threshold_seconds: value }
    None => ()
  }
  match file_config.max_candidates {
    Some(value) => updated = { ..updated, max_candidates: value }
    None => ()
  }
  match file_config.allow_file_fallback {
    Some(value) => updated = { ..updated, allow_file_fallback: value }
    None => ()
  }
  match file_config.git_preferred {
    Some(value) => updated = { ..updated, git_preferred: value }
    None => ()
  }
  match file_config.mtime_fallback {
    Some(value) => updated = { ..updated, mtime_fallback: value }
    None => ()
  }
  match file_config.logical_review_mode {
    Some(value) => updated = { ..updated, logical_review_mode: value }
    None => ()
  }
  updated
}

///|
pub fn resolve_config(args : Array[String], start_idx : Int) -> ReconcileConfig {
  let defaults = ReconcileConfig::default()
  let parsed = parse_args(args, start_idx)
  let target_dir = @config_paths.normalize_path(
    if parsed.target_dir.length() > 0 {
      parsed.target_dir
    } else {
      "."
    },
  )
  let config_path = @config_paths.find_indexion_config_path(
    target_dir,
    explicit_path=parsed.config_path,
  )
  let file_config = @config_paths.load_reconcile_file_config(config_path)
  let base = {
    ..parsed,
    target_dir,
    config_path,
    specs_dir: resolve_specs_dir(target_dir, specs_dir=parsed.specs_dir),
  }
  let merged = apply_file_config(base, file_config)
  {
    ..merged,
    index_dir: if parsed.index_dir != defaults.index_dir {
      @config_paths.resolve_path(target_dir, parsed.index_dir)
    } else {
      match file_config.index_dir {
        Some(value) =>
          @config_paths.resolve_config_path_value(
            target_dir, config_path, value,
          )
        None => @config_paths.default_tool_dir(target_dir, defaults.index_dir)
      }
    },
    review_results_path: if parsed.review_results_path.length() > 0 {
      @config_paths.resolve_path(target_dir, parsed.review_results_path)
    } else {
      match file_config.review_results_path {
        Some(value) =>
          @config_paths.resolve_config_path_value(
            target_dir, config_path, value,
          )
        None => ""
      }
    },
    specs_dir: if parsed.specs_dir.length() > 0 {
      @config_paths.resolve_path(target_dir, parsed.specs_dir)
    } else {
      resolve_specs_dir(target_dir)
    },
  }
}

///|
pub fn show_help() -> Unit {
  println("indexion plan reconcile - Detect implementation/documentation drift")
  println("")
  println("Usage:")
  println("  indexion plan reconcile [options] <directory>")
  println("")
  println("Options:")
  println("  --output=FILE, -o=     Output file path (default: stdout)")
  println(
    "  --format=FORMAT        Output format: json, md, github-issue (default: json)",
  )
  println("  --specs=DIR            KGF specs directory (default: auto-detect)")
  println(
    "  --index-dir=DIR        Cache directory (default: .indexion/reconcile)",
  )
  println(
    "  --config=FILE          Explicit config file (.indexion.toml or .json)",
  )
  println("  --review-results=FILE  Apply logical review decisions from JSON")
  println("  --threshold-seconds=N  Drift threshold in seconds (default: 60)")
  println(
    "  --max-candidates=N     Maximum candidates in output (default: 200)",
  )
  println("  --doc=GLOB             Restrict document paths (repeatable)")
  println("  --doc-spec=NAME        Restrict document KGF specs (repeatable)")
  println(
    "  --no-file-fallback     Disable basename/file-path fallback matching",
  )
  println(
    "  --mtime-only           Skip git timestamps and rely on file mtimes",
  )
  println("  --logical-review=MODE  queue or off (default: queue)")
  println("  --help                 Show this help message")
  println("")
  println("Config files:")
  println("  .indexion.toml is preferred over .indexion.json")
  println("")
  println("Examples:")
  println("  indexion plan reconcile .")
  println("  indexion plan reconcile --format=md src/")
  println(
    "  indexion plan reconcile --doc='docs/**/*.md' --doc='spec/**/*.toml' .",
  )
}
