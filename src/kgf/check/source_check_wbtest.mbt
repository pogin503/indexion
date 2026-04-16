///|
fn simple_check_spec() -> @kgf_types.KGFSpec {
  @kgf_types.KGFSpec::new(
    "test",
    tokens=[
      @kgf_types.TokenDef::new("IDENT", "[a-z]+"),
      @kgf_types.TokenDef::new("NUMBER", "[0-9]+"),
      @kgf_types.TokenDef::new("WS", "\\s+", skip=true),
    ],
    rules={
      "Doc": @kgf_types.RuleDef::new("Doc", "IDENT NUMBER?"),
      "Pair": @kgf_types.RuleDef::new("Pair", "IDENT NUMBER"),
    },
  )
}

///|
test "check_source: valid source has no diagnostics" {
  let diagnostics = check_source("foo 42", "test.txt", simple_check_spec())
  assert_eq(diagnostics.length(), 0)
}

///|
test "check_source: reports lexer diagnostics with source position" {
  let diagnostics = check_source("foo @@", "test.txt", simple_check_spec())
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].get_file(), "test.txt")
  assert_eq(diagnostics[0].get_line(), 1)
  assert_eq(diagnostics[0].get_col(), 5)
  assert_eq(diagnostics[0].get_source(), "lexer")
  assert_true(diagnostics[0].get_message().contains("@@"))
}

///|
test "check_source: reports parser diagnostics with expected token" {
  let spec = @kgf_types.KGFSpec::new(
    "test",
    tokens=[
      @kgf_types.TokenDef::new("IDENT", "[a-z]+"),
      @kgf_types.TokenDef::new("NUMBER", "[0-9]+"),
      @kgf_types.TokenDef::new("WS", "\\s+", skip=true),
    ],
    rules={ "Doc": @kgf_types.RuleDef::new("Doc", "IDENT NUMBER") },
  )
  let diagnostics = check_source("foo bar", "test.txt", spec)
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].get_line(), 1)
  assert_eq(diagnostics[0].get_col(), 5)
  assert_eq(diagnostics[0].get_source(), "parser")
  assert_true(diagnostics[0].get_message().contains("NUMBER"))
  assert_true(diagnostics[0].get_message().contains("IDENT"))
}

///|
test "check_source: entirely unrecognized source only reports lexer" {
  let diagnostics = check_source("@@", "test.txt", simple_check_spec())
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].get_source(), "lexer")
}

///|
test "check_source: mermaid fixture is accepted" {
  let registry = @registry.KGFRegistry::load_from_dir(
    @kgf_fixtures.get_kgfs_dir(),
  )
  let spec = registry.get_spec("mermaid").unwrap()
  let path = @kgf_fixtures.get_fixtures_dir() + "/diagram/mermaid/gantt.mmd"
  let content = @fs.read_file_to_string(path) catch { _ => "" }
  if content.length() > 0 {
    let diagnostics = check_source(content, path, spec)
    assert_eq(diagnostics.length(), 0)
  }
}

///|
test "check_source: broken mermaid fixture reports diagnostics" {
  let registry = @registry.KGFRegistry::load_from_dir(
    @kgf_fixtures.get_kgfs_dir(),
  )
  let spec = registry.get_spec("mermaid").unwrap()
  let path = @kgf_fixtures.get_fixtures_dir() + "/diagram/mermaid/broken.mmd"
  let content = @fs.read_file_to_string(path) catch { _ => "" }
  if content.length() > 0 {
    let diagnostics = check_source(content, path, spec)
    assert_true(diagnostics.length() > 0)
    assert_true(diagnostics.iter().any(fn(d) { d.get_severity() == "error" }))
  }
}
