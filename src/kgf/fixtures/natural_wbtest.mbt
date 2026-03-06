///|
/// Natural language fixtures tests.
/// Validates KGF parsing for Japanese, English, Chinese, Korean.

///|
test "natural/japanese: tokenize text" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("japanese").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/natural/japanese/simple.txt",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Japanese text should have Kanji/Hiragana tokens
  let mut has_japanese = false
  for tok in tokens {
    if tok.kind == "Kanji" || tok.kind == "Hiragana" || tok.kind == "Katakana" {
      has_japanese = true
      break
    }
  }
  assert_true(has_japanese)
}

///|
test "natural/english: tokenize text" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("english").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/natural/english/sample.txt",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
}

///|
test "natural/korean: tokenize text" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("korean").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/natural/korean/sample.txt",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
}

///|
test "natural/chinese: tokenize text" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("chinese").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/natural/chinese/sample.txt",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
}
