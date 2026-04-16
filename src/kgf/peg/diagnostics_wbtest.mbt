///|
fn diagnostic_spec() -> @types.KGFSpec {
  @types.KGFSpec::new(
    "test",
    tokens=[
      @types.TokenDef::new("IDENT", "[a-z]+"),
      @types.TokenDef::new("NUMBER", "[0-9]+"),
      @types.TokenDef::new("STRING", "\"[^\"]*\""),
    ],
    rules={
      "start": @types.RuleDef::new("start", "IDENT NUMBER"),
      "choice": @types.RuleDef::new("choice", "IDENT (NUMBER | STRING)"),
      "single": @types.RuleDef::new("single", "IDENT"),
    },
  )
}

///|
test "run_parse_with_diagnostics: reports furthest failed token" {
  let spec = diagnostic_spec()
  let peg = build_peg(spec)
  let tokens = [
    @types.Tok::new("IDENT", "foo", 0),
    @types.Tok::new("IDENT", "bar", 4),
  ]
  let (result, diagnostic) = run_parse_with_diagnostics(
    peg, spec, "start", tokens,
  )
  assert_true(result is None)
  assert_eq(diagnostic.get_furthest_pos(), 1)
  assert_true(diagnostic.get_actual_token() is Some(_))
  assert_eq(diagnostic.get_actual_token().unwrap().get_kind(), "IDENT")
  assert_eq(diagnostic.get_expected_kinds().length(), 1)
  assert_eq(diagnostic.get_expected_kinds()[0], "NUMBER")
  assert_false(diagnostic.is_fully_consumed())
}

///|
test "run_parse_with_diagnostics: merges expected kinds at same position" {
  let spec = diagnostic_spec()
  let peg = build_peg(spec)
  let tokens = [
    @types.Tok::new("IDENT", "foo", 0),
    @types.Tok::new("IDENT", "bar", 4),
  ]
  let (_, diagnostic) = run_parse_with_diagnostics(peg, spec, "choice", tokens)
  assert_eq(diagnostic.get_furthest_pos(), 1)
  assert_eq(diagnostic.get_expected_kinds().length(), 2)
  assert_true(diagnostic.get_expected_kinds().contains("NUMBER"))
  assert_true(diagnostic.get_expected_kinds().contains("STRING"))
}

///|
test "run_parse_with_diagnostics: reports partial consumption" {
  let spec = diagnostic_spec()
  let peg = build_peg(spec)
  let tokens = [
    @types.Tok::new("IDENT", "foo", 0),
    @types.Tok::new("NUMBER", "42", 4),
  ]
  let (result, diagnostic) = run_parse_with_diagnostics(
    peg, spec, "single", tokens,
  )
  assert_true(result is Some(_))
  assert_eq(result.unwrap().get_pos(), 1)
  assert_eq(diagnostic.get_furthest_pos(), 1)
  assert_true(diagnostic.get_actual_token() is Some(_))
  assert_eq(diagnostic.get_actual_token().unwrap().get_kind(), "NUMBER")
  assert_false(diagnostic.is_fully_consumed())
}

///|
test "run_parse_with_diagnostics: marks fully consumed success" {
  let spec = diagnostic_spec()
  let peg = build_peg(spec)
  let tokens = [
    @types.Tok::new("IDENT", "foo", 0),
    @types.Tok::new("NUMBER", "42", 4),
  ]
  let (result, diagnostic) = run_parse_with_diagnostics(
    peg, spec, "start", tokens,
  )
  assert_true(result is Some(_))
  assert_eq(result.unwrap().get_pos(), 2)
  assert_eq(diagnostic.get_furthest_pos(), 2)
  assert_true(diagnostic.get_actual_token() is None)
  assert_true(diagnostic.is_fully_consumed())
}
