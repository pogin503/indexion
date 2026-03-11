///|
test "reconcile: parse_toml_config supports nested sections" {
  let input =
    #|[reconcile]
    #|doc_paths = ["docs/**/*.md", "spec/**/*.toml"]
    #|review_results_path = ".indexion/reconcile/reviews.json"
    #|threshold_seconds = 120
    #|
    #|[reconcile.mapping]
    #|allow_file_fallback = false
    #|
    #|[reconcile.output]
    #|default_format = "md"
    #|
    #|[reconcile.time]
    #|git_preferred = true
    #|mtime_fallback = false
    #|
    #|[reconcile.logical_review]
    #|mode = "off"
  let config = @config_paths.parse_reconcile_toml_config(input)
  assert_true(config.doc_paths is Some(_))
  assert_eq(config.doc_paths.unwrap()[0], "docs/**/*.md")
  assert_eq(
    config.review_results_path,
    Some(".indexion/reconcile/reviews.json"),
  )
  assert_eq(config.threshold_seconds, Some(120))
  assert_eq(config.allow_file_fallback, Some(false))
  assert_eq(config.format, Some("md"))
  assert_eq(config.mtime_fallback, Some(false))
  assert_eq(config.logical_review_mode, Some("off"))
}

///|
fn temp_reconcile_dir(prefix : String) -> String {
  prefix + @env.now().to_string()
}

///|
fn load_test_registry() -> @registry.KGFRegistry {
  @registry.KGFRegistry::load_from_dir("kgfs")
}

///|
fn remove_file_if_exists(path : String) -> Unit {
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  if @fs.path_exists(path) {
    @fs.remove_dir(path) catch {
      _ => ()
    }
  }
}

///|
test "reconcile: resolve_config keeps default index dir under target root" {
  let dir = temp_reconcile_dir(".indexion/reconcile-config-default-")
  @config_paths.ensure_dir_recursive(dir)
  let config = resolve_config([dir], 0)
  assert_eq(config.target_dir, dir)
  assert_eq(config.index_dir, dir + "/.indexion/reconcile")
  remove_dir_if_exists(dir)
}

///|
test "reconcile: resolve_config rebases config-relative paths" {
  let dir = temp_reconcile_dir(".indexion/reconcile-config-file-")
  @config_paths.ensure_dir_recursive(dir)
  let config_path = dir + "/.indexion.toml"
  let config_content =
    #|[reconcile]
    #|index_dir = ".cache/reconcile-db"
    #|review_results_path = ".indexion/reconcile/reviews.json"
  @fs.write_string_to_file(config_path, config_content) catch {
    _ => ()
  }
  let config = resolve_config([dir], 0)
  assert_eq(config.config_path, config_path)
  assert_eq(config.index_dir, dir + "/.cache/reconcile-db")
  assert_eq(
    config.review_results_path,
    dir + "/.indexion/reconcile/reviews.json",
  )
  remove_file_if_exists(config_path)
  remove_dir_if_exists(dir)
}

///|
test "reconcile: resolve_config rebases cli relative paths to target root" {
  let dir = temp_reconcile_dir(".indexion/reconcile-config-cli-")
  @config_paths.ensure_dir_recursive(dir)
  let config = resolve_config(
    [
      "--index-dir=.cache/reconcile-db", "--review-results=.indexion/reconcile/reviews.json",
      dir,
    ],
    0,
  )
  assert_eq(config.index_dir, dir + "/.cache/reconcile-db")
  assert_eq(
    config.review_results_path,
    dir + "/.indexion/reconcile/reviews.json",
  )
  remove_dir_if_exists(dir)
}

///|
test "reconcile: extract_markdown_fragments keeps headings and paragraphs" {
  let input =
    #|# API
    #|
    #|`buildGraph` collects modules.
    #|
    #|## Notes
    #|The CLI prints json.
  let fragments = extract_markdown_fragments("README.md", "markdown", input)
  assert_true(fragments.length() >= 3)
  assert_eq(fragments[0].kind, "heading")
  assert_eq(fragments[1].kind, "paragraph")
  assert_true(fragments[1].content.contains("buildGraph"))
}

///|
test "reconcile: extract_toml_fragments keeps section keys" {
  let input =
    #|[project]
    #|name = "demo"
    #|description = "Build graph"
  let fragments = extract_toml_fragments("pyproject.toml", "toml", input)
  assert_true(fragments.length() >= 3)
  assert_eq(fragments[0].kind, "section")
  assert_eq(fragments[1].title, "project.name")
}

///|
test "reconcile: build_candidates reports stale and missing docs" {
  let config = {
    ..ReconcileConfig::default(),
    target_dir: ".",
    threshold_seconds: 10,
  }
  let units : Array[CodeUnit] = [
    {
      symbol_id: "sym:buildGraph",
      name: "buildGraph",
      kind: "function",
      ns: "pkg.graph",
      module_id: "pkg.graph",
      module_path: "src/engine.mbt",
      inline_doc: None,
      code_hash: "code-1",
    },
    {
      symbol_id: "sym:noDoc",
      name: "noDoc",
      kind: "function",
      ns: "pkg.graph",
      module_id: "pkg.graph",
      module_path: "src/engine.mbt",
      inline_doc: None,
      code_hash: "code-2",
    },
  ]
  let fragments : Array[DocFragment] = [
    make_fragment(
      "docs/api.md", "markdown", "paragraph", "API", "The `buildGraph` helper renders output.",
    ),
  ]
  let result = build_candidates(units, fragments, config, load_test_registry())
  assert_true(result.candidates.length() >= 1)
  assert_true(
    result.candidates
    .iter()
    .any(fn(candidate) {
      candidate.symbol_id == "sym:noDoc" && candidate.status == "missing_doc"
    }),
  )
}

///|
test "reconcile: build_candidates suppresses missing_doc when module docs cover the file" {
  let dir = temp_reconcile_dir(".indexion/reconcile-module-coverage-")
  @config_paths.ensure_dir_recursive(dir)
  let module_path = dir + "/config.mbt"
  let module_source =
    #|fn resolve_config() -> Unit { ignore(()) }
    #|fn parse_args() -> Unit { ignore(()) }
    #|let doc_paths = ""
    #|let doc_specs = ""
    #|let index_dir = ""
    #|let review_results_path = ""
  @fs.write_string_to_file(module_path, module_source) catch {
    _ => ()
  }
  let config = {
    ..ReconcileConfig::default(),
    target_dir: dir,
    threshold_seconds: 10,
  }
  let units : Array[CodeUnit] = [
    {
      symbol_id: "sym:resolve_config",
      name: "resolve_config",
      kind: "function",
      ns: "pkg.reconcile",
      module_id: "pkg.reconcile.config",
      module_path,
      inline_doc: None,
      code_hash: "code-1",
    },
    {
      symbol_id: "sym:parse_args",
      name: "parse_args",
      kind: "function",
      ns: "pkg.reconcile",
      module_id: "pkg.reconcile.config",
      module_path,
      inline_doc: None,
      code_hash: "code-2",
    },
  ]
  let fragments : Array[DocFragment] = [
    make_fragment(
      dir + "/README.md",
      "markdown",
      "paragraph",
      "Configuration",
      "The configuration supports doc_paths, doc_specs, index_dir, and review_results_path.",
    ),
  ]
  let result = build_candidates(units, fragments, config, load_test_registry())
  assert_eq(result.candidates.length(), 0)
  assert_eq(result.module_covered_symbols, 2)
  remove_file_if_exists(module_path)
  remove_dir_if_exists(dir)
}

///|
test "reconcile: match_fragment requires exact token for plain symbol names" {
  let generic_unit : CodeUnit = {
    symbol_id: "sym:run",
    name: "run",
    kind: "function",
    ns: "pkg.reconcile",
    module_id: "pkg.reconcile.cli",
    module_path: "src/cli.mbt",
    inline_doc: None,
    code_hash: "code-run",
  }
  let rerun_fragment = make_fragment(
    "README.md", "markdown", "paragraph", "Workflow", "Re-running reconcile reuses pending tasks.",
  )
  let default_fragment = make_fragment(
    "README.md", "markdown", "paragraph", "Configuration", "[reconcile.output] default_format = \"json\"",
  )
  let default_column_fragment = make_fragment(
    "README.md", "markdown", "paragraph", "Options", "| Option | Purpose | Default |",
  )
  let registry = load_test_registry()
  let markdown_signals = build_fragment_match_signals(
    [rerun_fragment, default_fragment, default_column_fragment],
    registry,
  )
  assert_eq(
    match_fragment(
      generic_unit,
      rerun_fragment,
      markdown_signals.get(rerun_fragment.id).unwrap(),
      true,
    ).0,
    0,
  )
  assert_eq(
    match_fragment(
      { ..generic_unit, name: "default" },
      default_fragment,
      markdown_signals.get(default_fragment.id).unwrap(),
      true,
    ).0,
    0,
  )
  assert_eq(
    match_fragment(
      { ..generic_unit, name: "default" },
      default_column_fragment,
      markdown_signals.get(default_column_fragment.id).unwrap(),
      true,
    ).0,
    0,
  )
  let structured_unit : CodeUnit = {
    ..generic_unit,
    symbol_id: "sym:parse_args",
    name: "parse_args",
  }
  let exact_fragment = make_fragment(
    "settings.toml", "toml", "entry", "reconcile.parse_args", "parse_args = true",
  )
  let toml_signals = build_fragment_match_signals([exact_fragment], registry)
  let matched = match_fragment(
    structured_unit,
    exact_fragment,
    toml_signals.get(exact_fragment.id).unwrap(),
    true,
  )
  assert_eq(matched.0, 85)
  assert_eq(matched.1, "symbol_name")
}

///|
test "reconcile: extract_code_units uses KGF document_symbol_kinds when available" {
  let registry = load_test_registry()
  let graph = @graph.CodeGraph::new()
  let _ = graph.get_or_add_module("src/demo.mbt", file=Some("src/demo.mbt"))
  let _ = graph.get_or_add_symbol(
    "src/demo.mbt::value:build_graph",
    name="build_graph",
    kind="Function",
    ns="value",
    module_id="src/demo.mbt",
  )
  let _ = graph.get_or_add_symbol(
    "src/demo.mbt::value:default_format",
    name="default_format",
    kind="Variable",
    ns="value",
    module_id="src/demo.mbt",
  )
  let units = extract_code_units(graph, registry)
  assert_true(
    units
    .iter()
    .any(fn(unit) { unit.symbol_id == "src/demo.mbt::value:build_graph" }),
  )
  assert_true(
    not(
      units
      .iter()
      .any(fn(unit) { unit.symbol_id == "src/demo.mbt::value:default_format" }),
    ),
  )
}

///|
test "reconcile: extract_code_units falls back for unknown specs" {
  let registry = load_test_registry()
  let graph = @graph.CodeGraph::new()
  let _ = graph.get_or_add_module(
    "src/demo.unknown",
    file=Some("src/demo.unknown"),
  )
  let _ = graph.get_or_add_symbol(
    "src/demo.unknown::value:build_graph",
    name="build_graph",
    kind="Function",
    ns="value",
    module_id="src/demo.unknown",
  )
  let units = extract_code_units(graph, registry)
  assert_true(
    units
    .iter()
    .any(fn(unit) { unit.symbol_id == "src/demo.unknown::value:build_graph" }),
  )
}

///|
test "reconcile: discovery_roots expands current directory instead of '.'" {
  let roots = discovery_roots(".")
  assert_true(roots.length() > 0)
  assert_true(not(contains_string(roots, ".")))
}

///|
test "reconcile: git query path strips target root prefix" {
  assert_eq(
    @git.query_path(
      "cmd/indexion/plan/reconcile", "cmd/indexion/plan/reconcile/cli.mbt",
    ),
    "cli.mbt",
  )
  assert_eq(
    @git.query_path(".", "cmd/indexion/plan/reconcile/cli.mbt"),
    "cmd/indexion/plan/reconcile/cli.mbt",
  )
}

///|
test "reconcile: cleanup_stale_index removes dead index.json" {
  let dir = temp_reconcile_dir(".indexion/reconcile-cleanup-")
  @config_paths.ensure_dir_recursive(dir)
  @fs.write_string_to_file(dir + "/index.json", "{}") catch {
    _ => ()
  }
  cleanup_stale_index(dir)
  assert_true(not(@fs.path_exists(dir + "/index.json")))
  remove_dir_if_exists(dir)
}

///|
fn sample_code_anchor() -> CodeAnchor {
  {
    symbol_id: "sym:buildGraph",
    name: "buildGraph",
    kind: "function",
    ns: "pkg.graph",
    module_path: "src/graph.mbt",
    inline_doc: None,
  }
}

///|
fn sample_doc_anchor() -> DocAnchor {
  {
    fragment_id: "frag:api",
    path: "docs/api.md",
    spec: "markdown",
    kind: "paragraph",
    title: "API",
    preview: "The `buildGraph` helper renders the graph.",
  }
}

///|
fn sample_timestamp(epoch_seconds : Int) -> TimestampInfo {
  { epoch_seconds: Some(epoch_seconds), source: "git", is_dirty: false }
}

///|
fn sample_candidate() -> ReconcileCandidate {
  {
    id: "cand:buildGraph",
    symbol_id: "sym:buildGraph",
    status: "stale_doc",
    time_relation: "doc_older",
    mapping_confidence: 95,
    recommended_action: "update_doc",
    mechanical_digest: "",
    code_anchor: sample_code_anchor(),
    doc_anchor: Some(sample_doc_anchor()),
    evidence: {
      matched_terms: ["buildGraph"],
      match_kind: "inline_symbol",
      reason: "Implementation appears newer than the mapped document fragment.",
      code_time: sample_timestamp(200),
      doc_time: sample_timestamp(100),
    },
    logical_review_key: None,
    logical_review_status: "pending",
    logical_review_reused: false,
    needs_logical_review: true,
  }
}

///|
test "reconcile: sync_candidates_with_index reuses pending logical review tasks" {
  let first = sync_candidates_with_index(
    [sample_candidate()],
    ReconcileManifest::empty(),
    @vcdb.VectorDB::with_dim(1),
    "queue",
    1000,
  )
  assert_eq(first.logical_reviews.length(), 1)
  assert_eq(first.logical_reviews[0].status, "pending")
  assert_true(not(first.logical_reviews[0].reused))
  assert_eq(first.reused_logical_reviews, 0)

  let second = sync_candidates_with_index(
    [sample_candidate()],
    first.manifest,
    first.db,
    "queue",
    1100,
  )
  assert_eq(second.logical_reviews.length(), 1)
  assert_true(second.logical_reviews[0].reused)
  assert_eq(second.reused_logical_reviews, 1)
  assert_eq(second.candidates[0].logical_review_status, "pending")
  assert_true(second.candidates[0].logical_review_reused)
  assert_true(second.candidates[0].needs_logical_review)

  let summary = build_summary(
    [],
    [],
    second.candidates,
    0,
    second.logical_reviews,
    second.reused_logical_reviews,
  )
  assert_eq(summary.new_logical_reviews, 0)
  assert_eq(summary.reused_logical_reviews, 1)
  assert_eq(summary.pending_logical_reviews, 1)
}

///|
test "reconcile: apply_review_decisions closes pending logical review" {
  let first = sync_candidates_with_index(
    [sample_candidate()],
    ReconcileManifest::empty(),
    @vcdb.VectorDB::with_dim(1),
    "queue",
    1000,
  )
  let review_key = first.logical_reviews[0].review_key
  let decisions : Array[ReviewDecisionInput] = [
    { review_key, status: "accepted", verdict: Some("document needs update") },
  ]
  let (manifest_after_review, db_after_review) = apply_review_decisions(
    first.manifest,
    first.db,
    decisions,
    1200,
  )
  let second = sync_candidates_with_index(
    [sample_candidate()],
    manifest_after_review,
    db_after_review,
    "queue",
    1300,
  )
  assert_eq(second.logical_reviews.length(), 0)
  assert_eq(second.reused_logical_reviews, 0)
  assert_eq(second.candidates[0].logical_review_key, Some(review_key))
  assert_eq(second.candidates[0].logical_review_status, "accepted")
  assert_true(second.candidates[0].logical_review_reused)
  assert_true(not(second.candidates[0].needs_logical_review))
}
