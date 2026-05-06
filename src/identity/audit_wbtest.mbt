///|
test "identity audit: repeated basenames are scoped by parent directory" {
  let model : PathNameModel = {
    basename_counts: { "main.mbt": 2, "unique.mbt": 1 },
  }
  assert_eq(scoped_path_name("src/a/main.mbt", model), "a main")
  assert_eq(scoped_path_name("src/b/main.mbt", model), "b main")
  assert_eq(scoped_path_name("src/a/unique.mbt", model), "unique")
}

///|
test "identity audit: path scope terms are derived from path structure" {
  let terms = path_scope_terms("cmd/indexion/identity/cli.mbt")
  assert_true(terms.contains("cmd"))
  assert_true(terms.contains("indexion"))
  assert_true(terms.contains("identity"))
  assert_true(terms.contains("cli"))
}
