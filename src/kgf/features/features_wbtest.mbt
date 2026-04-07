///|
fn test_registry() -> @kgf_registry.KGFRegistry {
  load_registry_or_empty(specs_dir="kgfs", target_dir=".")
}

///|
test "is_document_file detects markdown and code separately" {
  let registry = test_registry()
  assert_eq(is_document_file("README.md", Some(registry)), Some(true))
  assert_eq(is_document_file("src/main.ts", Some(registry)), Some(false))
}

///|
test "is_document_file supports rfc plaintext fixture suffix" {
  let registry = test_registry()
  assert_eq(
    is_document_file("fixtures/spec/rfc2795.rfc.txt", Some(registry)),
    Some(true),
  )
}
