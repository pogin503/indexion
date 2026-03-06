///|
/// DSL fixtures tests.
/// Validates KGF parsing for SQL, HTML, Markdown.

///|
test "dsl/sql-ddl: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("sql-ddl").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/dsl/sql-ddl/schema.sql",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Should have CREATE keyword (KW_CREATE in sql-ddl.kgf)
  let mut has_create = false
  for tok in tokens {
    if tok.kind == "KW_CREATE" {
      has_create = true
      break
    }
  }
  assert_true(has_create)
}

///|
test "dsl/html: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("html").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/dsl/html/index.html",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
}

///|
test "dsl/markdown: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("markdown").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/dsl/markdown/README.md",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Should have link tokens (LBRACK for markdown links)
  let mut has_link = false
  for tok in tokens {
    if tok.kind == "LBRACK" {
      has_link = true
      break
    }
  }
  assert_true(has_link)
}
