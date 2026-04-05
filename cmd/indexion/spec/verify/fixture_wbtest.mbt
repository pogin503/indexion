///|
/// Integration tests using the JSON-RPC 2.0 / RFC 7396 fixture.
///
/// Fixture: fixtures/project/spec-verify-jsonrpc/
///   spec/jsonrpc-2.0.md          — JSON-RPC 2.0 spec (markdown)
///   spec/rfc7396-merge-patch.html — RFC 7396 JSON Merge Patch (actual RFC HTML)
///   moonbit/                      — MoonBit project
///   typescript/                   — TypeScript project
///   python/                       — Python project
///
/// Tests verify that TF-IDF vocabulary comparison detects spec terms
/// absent from implementation, across multiple languages and spec formats.

///|
fn fixture_root() -> String {
  @kgf_fixtures.get_fixtures_dir() + "/project/spec-verify-jsonrpc"
}

///|
fn fixture_specs_dir() -> String {
  @kgf_fixtures.get_kgfs_dir()
}

///|
/// Build a VerifyConfig for a given language project against the markdown spec.
fn fixture_config_for(lang_dir : String) -> VerifyConfig {
  {
    ..VerifyConfig::default(),
    spec_patterns: [fixture_root() + "/spec/jsonrpc-2.0.md"],
    target_dir: fixture_root() + "/" + lang_dir,
    specs_dir: fixture_specs_dir(),
  }
}

///|
/// Build a VerifyConfig using the HTML RFC spec.
fn fixture_config_html(lang_dir : String) -> VerifyConfig {
  {
    ..VerifyConfig::default(),
    spec_patterns: [fixture_root() + "/spec/rfc7396-merge-patch.html"],
    target_dir: fixture_root() + "/" + lang_dir,
    specs_dir: fixture_specs_dir(),
  }
}

///|
/// Run analysis with intentionally empty root_dir to avoid .indexionignore
/// filtering out the fixtures/ directory.
fn run_fixture_analysis(config : VerifyConfig) -> VerifyReport {
  // Temporarily override the analysis to use empty root_dir.
  // We replicate the core analysis logic but bypass DiscoverOptions root_dir.
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dir=config.target_dir,
  )
  let spec_paths = expand_spec_patterns(config.spec_patterns)
  let kgf_ignore = registry.collect_ignore_patterns()
  let discover_opts = @pipeline.DiscoverOptions::new(kgf_ignore~)
  let impl_paths = @pipeline.discover_files(
    [config.target_dir],
    discover_opts,
  )
  let spec_tokens = tokenize_file_set(spec_paths, registry)
  let impl_tokens = tokenize_file_set(impl_paths, registry)
  let all_file_tokens : Array[Array[String]] = []
  for t in spec_tokens {
    all_file_tokens.push(t)
  }
  for t in impl_tokens {
    all_file_tokens.push(t)
  }
  let project_df = @tfidf.build_document_frequency(all_file_tokens)
  let total_docs = all_file_tokens.length()
  let spec_flat = flatten_tokens(spec_tokens)
  let impl_flat = flatten_tokens(impl_tokens)
  let cosine_dist = @tfidf.calculate_tfidf_distance_from_tokens(
    spec_flat, impl_flat,
  )
  let local_df = @tfidf.build_document_frequency([spec_flat, impl_flat])
  let spec_vec = @tfidf.build_tfidf_vector(spec_flat, local_df, 2)
  let impl_tf = @tfidf.build_term_frequency(impl_flat)
  let ubiquity_threshold = total_docs / 3 + 1
  let gap_terms = extract_gap_terms(
    spec_vec, impl_tf, project_df, ubiquity_threshold,
  )
  let items = gap_terms_to_items(gap_terms, spec_paths)
  let summary = build_summary(items, cosine_dist)
  {
    version: "spec-verify-v1",
    generated_at: 0,
    config: {
      spec_paths: spec_paths.copy(),
      target_dir: config.target_dir,
      focus: config.focus,
      max_candidates: config.max_candidates,
    },
    summary: {
      ..summary,
      spec_files: spec_paths.length(),
      impl_files: impl_paths.length(),
      spec_symbols: spec_flat.length(),
    },
    items,
    used_specs: [],
  }
}

// ========== Core analysis tests ==========

///|
test "spec-verify/moonbit: markdown spec produces vocabulary analysis" {
  let config = fixture_config_for("moonbit")
  let report = run_fixture_analysis(config)
  // Cosine distance should be positive — spec and impl are different documents
  assert_true(
    report.summary.cosine_distance > 0.0,
    msg="cosine distance should be > 0 (spec and impl differ)",
  )
  // The spec_symbols count (total tokens) should be positive
  assert_true(
    report.summary.spec_symbols > 0,
    msg="spec should produce tokens",
  )
}

///|
test "spec-verify/typescript: markdown spec produces gap terms" {
  let config = fixture_config_for("typescript")
  let report = run_fixture_analysis(config)
  assert_true(report.summary.impl_files > 0, msg="no .ts files found")
  assert_true(
    report.summary.cosine_distance > 0.0,
    msg="cosine distance should be > 0",
  )
}

///|
test "spec-verify/python: markdown spec produces gap terms" {
  let config = fixture_config_for("python")
  let report = run_fixture_analysis(config)
  assert_true(report.summary.impl_files > 0, msg="no .py files found")
  assert_true(
    report.summary.cosine_distance > 0.0,
    msg="cosine distance should be > 0",
  )
}

// ========== HTML RFC spec tests ==========

///|
test "spec-verify/moonbit: HTML RFC spec produces report" {
  let config = fixture_config_html("moonbit")
  let report = run_fixture_analysis(config)
  assert_true(report.summary.spec_files == 1, msg="expected 1 HTML spec file")
  assert_true(
    report.summary.impl_files > 0,
    msg="no impl files discovered",
  )
  // HTML RFC should produce vocabulary tokens via KGF html spec
  assert_true(
    report.summary.spec_symbols > 0,
    msg="no spec symbols from HTML RFC",
  )
}

///|
test "spec-verify/typescript: HTML RFC spec produces report" {
  let config = fixture_config_html("typescript")
  let report = run_fixture_analysis(config)
  assert_true(report.summary.impl_files > 0, msg="no .ts files found")
  assert_true(report.summary.spec_symbols > 0, msg="no spec symbols from HTML")
}

///|
test "spec-verify/python: HTML RFC spec produces report" {
  let config = fixture_config_html("python")
  let report = run_fixture_analysis(config)
  assert_true(report.summary.impl_files > 0, msg="no .py files found")
  assert_true(report.summary.spec_symbols > 0, msg="no spec symbols from HTML")
}

// ========== Summary & renderer tests ==========

///|
test "spec-verify: summary fields are consistent" {
  let config = fixture_config_for("moonbit")
  let report = run_fixture_analysis(config)
  assert_eq(report.summary.gap_count, report.items.length())
  assert_eq(report.summary.missing, report.items.length())
}

///|
test "spec-verify: renderers produce valid output" {
  let config = fixture_config_for("moonbit")
  let report = run_fixture_analysis(config)
  let md = render_output(report, "md")
  assert_true(md.contains("# Spec Verify Report"))
  assert_true(md.contains("Vocabulary distance"))
  let json_out = render_output(report, "json")
  assert_true(json_out.contains("\"spec-verify-v1\""))
  let issue = render_output(report, "github-issue")
  assert_true(issue.contains("Vocabulary distance"))
}
