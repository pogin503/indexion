///|
fn temp_dir(label : String) -> String {
  let dir = "/tmp/indexion-spec-draft/" + label + "-" + @env.now().to_string()
  @config.ensure_dir_recursive(dir)
  dir
}

///|
fn fixture_doc(root : String) -> String {
  let path = root + "/README.md"
  let text =
    #|# Tool
    #|
    #|- `diff` detects drift between spec and implementation.
    #|- `status` fails CI when drift is detected.
    #|
    #|## Usage
    #|
    #|Use the generated native binary for CI.
  @fs.write_string_to_file(path, text) catch {
    _ => panic()
  }
  path
}

///|
fn rfc3492_spec_path() -> String {
  "fixtures/project/spec-align-rfc3492/spec/rfc3492.rfc.txt"
}

///|
fn rfc3492_impl_path() -> String {
  "fixtures/project/spec-align-rfc3492/typescript"
}

///|
fn rfc2795_spec_path() -> String {
  "fixtures/project/spec-align-rfc2795/spec/rfc2795.rfc.txt"
}

///|
fn rfc2795_impl_path() -> String {
  "fixtures/project/spec-align-rfc2795/typescript"
}

///|
test "spec-draft: bullet list yields numbered requirements" {
  let root = temp_dir("fixture")
  let path = fixture_doc(root)
  let report = match
    report({ ..DraftConfig::default(), source_path: path, specs_dir: "kgfs" }) {
    Some(value) => value
    None => fail("expected draft report")
  }
  assert_true(report.requirements.length() >= 2)
  assert_eq(report.requirements[0].id, "REQ-1")
  assert_eq(report.requirements[0].title, "Tool")
}

///|
test "spec-draft: render markdown emits requirement headings" {
  let root = temp_dir("render")
  let path = fixture_doc(root)
  let rendered = match
    run_to_string({
      ..DraftConfig::default(),
      source_path: path,
      specs_dir: "kgfs",
      format: "markdown",
    }) {
    Some(value) => value
    None => fail("expected rendered draft")
  }
  assert_true(rendered.contains("## Requirement 1:"))
  assert_true(rendered.contains("diff"))
}

///|
async test "spec-draft: RFC 3492 fixture drafts and aligns under current benchmark" {
  let draft_dir = temp_dir("rfc3492")
  let draft_path = draft_dir + "/draft.md"
  let rendered = match
    run_to_string({
      ..DraftConfig::default(),
      source_path: rfc3492_spec_path(),
      specs_dir: "kgfs",
    }) {
    Some(value) => value
    None => fail("expected RFC 3492 draft")
  }
  @fs.write_string_to_file(draft_path, rendered) catch {
    _ => panic()
  }
  assert_true(rendered.contains("6.1 Bias adaptation function"))
  let diff = match
    @spec_align.diff_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      spec_path: draft_path,
      impl_path: rfc3492_impl_path(),
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.186,
    }) {
    Some(value) => value
    None => fail("expected RFC 3492 diff report")
  }
  assert_true(diff.summary.total_requirements > 0)
  assert_true(diff.summary.matched > 0)
  assert_true(
    diff.items.any(fn(item) {
      item.category == "MATCHED" &&
      item.requirement_title.unwrap_or("").contains("Bias adaptation")
    }),
  )
  let status = match
    @spec_align.status_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      subcommand: "status",
      spec_path: draft_path,
      impl_path: rfc3492_impl_path(),
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.186,
      fail_on: "drifted",
    }) {
    Some(value) => value
    None => fail("expected RFC 3492 status report")
  }
  assert_false(status.should_fail)
  let suggest = match
    @spec_align.suggest_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      subcommand: "suggest",
      spec_path: draft_path,
      impl_path: rfc3492_impl_path(),
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.186,
      direction: "both",
    }) {
    Some(value) => value
    None => fail("expected RFC 3492 suggest report")
  }
  assert_true(suggest.suggestions.length() > 0)
}

///|
async test "spec-draft: RFC 2795 fixture drafts and produces drift on code table fixture" {
  let draft_dir = temp_dir("rfc2795")
  let draft_path = draft_dir + "/draft.md"
  let rendered = match
    run_to_string({
      ..DraftConfig::default(),
      source_path: rfc2795_spec_path(),
      specs_dir: "kgfs",
    }) {
    Some(value) => value
    None => fail("expected RFC 2795 draft")
  }
  @fs.write_string_to_file(draft_path, rendered) catch {
    _ => panic()
  }
  assert_true(rendered.contains("## Requirement 1:"))
  assert_true(rendered.contains("KEEPER"))
  let diff = match
    @spec_align.diff_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      spec_path: draft_path,
      impl_path: rfc2795_impl_path(),
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.186,
    }) {
    Some(value) => value
    None => fail("expected RFC 2795 diff report")
  }
  assert_true(diff.summary.total_requirements > 0)
  assert_true(diff.summary.drifted > 0)
  assert_true(
    diff.items.any(fn(item) {
      item.category == "DRIFTED" &&
      item.implementation_name == Some("REQUEST_STOP")
    }),
  )
}

///|
async test "spec-draft: repo README can be drafted and aligned" {
  let draft_dir = temp_dir("dogfood")
  let draft_path = draft_dir + "/draft.md"
  let rendered = match
    run_to_string({
      ..DraftConfig::default(),
      source_path: "cmd/indexion/spec/align/README.md",
      specs_dir: "kgfs",
    }) {
    Some(value) => value
    None => fail("expected repo draft")
  }
  @fs.write_string_to_file(draft_path, rendered) catch {
    _ => panic()
  }
  let report = match
    @spec_align.diff_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      spec_path: draft_path,
      impl_path: "cmd/indexion/spec",
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.05,
    }) {
    Some(value) => value
    None => fail("expected dogfood diff report")
  }
  assert_true(report.summary.total_requirements > 0)
  assert_true(report.summary.drifted > 0)
  let trace = match
    @spec_align.trace_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      spec_path: draft_path,
      impl_path: "cmd/indexion/spec",
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.05,
      format: "json",
    }) {
    Some(value) => value
    None => fail("expected dogfood trace report")
  }
  assert_true(trace.edges.length() > 0)
  let suggest = match
    @spec_align.suggest_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      subcommand: "suggest",
      spec_path: draft_path,
      impl_path: "cmd/indexion/spec",
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.05,
      direction: "both",
    }) {
    Some(value) => value
    None => fail("expected dogfood suggest report")
  }
  assert_true(suggest.suggestions.length() > 0)
  let task_config = {
    ..@spec_align.SpecAlignConfig::default(),
    subcommand: "suggest",
    spec_path: draft_path,
    impl_path: "cmd/indexion/spec",
    specs_dir: "kgfs",
    cache_dir: draft_dir + "/cache",
    threshold: 0.05,
    direction: "both",
    format: "tasks",
  }
  let claude_tasks = match
    @align_cli.run_to_string({ ..task_config, agent: "claude" }) {
    Some(value) => value
    None => fail("expected claude tasks")
  }
  assert_true(claude_tasks.contains("# Claude Tasks"))
  let generic_tasks = match
    @align_cli.run_to_string({ ..task_config, agent: "generic" }) {
    Some(value) => value
    None => fail("expected generic tasks")
  }
  assert_true(generic_tasks.contains("# Spec Align Tasks"))
  let status = match
    @spec_align.status_report_async({
      ..@spec_align.SpecAlignConfig::default(),
      subcommand: "status",
      spec_path: draft_path,
      impl_path: "cmd/indexion/spec",
      specs_dir: "kgfs",
      cache_dir: draft_dir + "/cache",
      threshold: 0.05,
      fail_on: "none",
    }) {
    Some(value) => value
    None => fail("expected dogfood status report")
  }
  assert_eq(status.status, "pass")
  assert_eq(status.should_fail, false)
}
