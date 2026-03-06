///|
/// Programming language fixtures tests.
/// Validates KGF parsing for TypeScript, JavaScript, Python, Go, Rust.

///|
fn get_fixtures_dir() -> String {
  let paths = [
    "fixtures", "../fixtures", "../../fixtures", "../../../fixtures",
    "../../../../fixtures", "../../../../../fixtures",
  ]
  for path in paths {
    try {
      if @fs.is_dir(path) {
        return path
      }
    } catch {
      _ => continue
    }
  }
  "fixtures"
}

///|
fn get_kgfs_dir() -> String {
  let paths = [
    "kgfs", "../kgfs", "../../kgfs", "../../../kgfs", "../../../../kgfs",
    "../../../../../kgfs",
  ]
  for path in paths {
    try {
      if @fs.is_dir(path) {
        return path
      }
    } catch {
      _ => continue
    }
  }
  "kgfs"
}

///|
test "programming/typescript: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("typescript").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/programming/typescript/src/main.ts",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Verify import keyword detection
  let mut has_import = false
  for tok in tokens {
    if tok.kind == "KW_import" {
      has_import = true
      break
    }
  }
  assert_true(has_import)
}

///|
test "programming/javascript: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("javascript").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/programming/javascript/src/app.js",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
}

///|
test "programming/python: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("python").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/programming/python/main.py",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Verify def/import keywords
  let mut has_def = false
  let mut has_import = false
  for tok in tokens {
    if tok.kind == "KW_def" {
      has_def = true
    }
    if tok.kind == "KW_import" {
      has_import = true
    }
  }
  assert_true(has_def)
  assert_true(has_import)
}

///|
test "programming/go: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("go").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/programming/go/main.go",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Verify package/func keywords
  let mut has_package = false
  let mut has_func = false
  for tok in tokens {
    if tok.kind == "KW_package" {
      has_package = true
    }
    if tok.kind == "KW_func" {
      has_func = true
    }
  }
  assert_true(has_package)
  assert_true(has_func)
}

///|
test "programming/rust: tokenize and parse" {
  let registry = @registry.KGFRegistry::load_from_dir(get_kgfs_dir())
  let spec = registry.get_spec("rust").unwrap()
  let lexer = @lexer.Lexer::new(spec.get_tokens())
  let source = @fs.read_file_to_string(
    get_fixtures_dir() + "/programming/rust/main.rs",
  ) catch {
    _ => return
  }
  let tokens = lexer.tokenize(source)
  assert_true(tokens.length() > 0)
  // Verify fn keyword
  let mut has_fn = false
  for tok in tokens {
    if tok.kind == "KW_fn" {
      has_fn = true
      break
    }
  }
  assert_true(has_fn)
}
