///|
test "tokenize_with_diagnostics: valid input has no diagnostics" {
  let lex = lexer()
    .token("IDENT", "[a-zA-Z_][a-zA-Z0-9_]*")
    .token("NUMBER", "\\d+")
    .skip("WS", "\\s+")
    .build()
  let (tokens, diagnostics) = lex.tokenize_with_diagnostics("foo 123")
  assert_eq(tokens.length(), 2)
  assert_eq(tokens[0].kind, "IDENT")
  assert_eq(tokens[1].kind, "NUMBER")
  assert_eq(diagnostics.length(), 0)
}

///|
test "tokenize_with_diagnostics: contiguous unmatched characters merge" {
  let lex = lexer().token("WORD", "[a-z]+").skip("WS", "\\s+").build()
  let (tokens, diagnostics) = lex.tokenize_with_diagnostics("foo @@@ bar")
  assert_eq(tokens.length(), 2)
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].get_pos(), 4)
  assert_eq(diagnostics[0].get_length(), 3)
  assert_eq(diagnostics[0].get_text(), "@@@")
}

///|
test "tokenize_with_diagnostics: separated unmatched spans stay separate" {
  let lex = lexer().token("WORD", "[a-z]+").skip("WS", "\\s+").build()
  let (_, diagnostics) = lex.tokenize_with_diagnostics("@@ foo ##")
  assert_eq(diagnostics.length(), 2)
  assert_eq(diagnostics[0].get_pos(), 0)
  assert_eq(diagnostics[0].get_text(), "@@")
  assert_eq(diagnostics[1].get_pos(), 7)
  assert_eq(diagnostics[1].get_text(), "##")
}

///|
test "tokenize_with_diagnostics: matches tokenize output" {
  let lex = lexer()
    .token("STRING", "\"[^\"]*\"")
    .token("IDENT", "[a-zA-Z]+")
    .skip("WS", "\\s+")
    .build()
  let plain = lex.tokenize("foo \"bar\" baz")
  let (diagnostic_tokens, diagnostics) = lex.tokenize_with_diagnostics(
    "foo \"bar\" baz",
  )
  assert_eq(diagnostics.length(), 0)
  assert_eq(diagnostic_tokens.length(), plain.length())
  for i in 0..<plain.length() {
    assert_eq(diagnostic_tokens[i].kind, plain[i].kind)
    assert_eq(diagnostic_tokens[i].text, plain[i].text)
    assert_eq(diagnostic_tokens[i].pos, plain[i].pos)
  }
}
