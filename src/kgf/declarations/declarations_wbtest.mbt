///|
fn registry() -> @kgf_registry.KGFRegistry {
  @kgf_registry.KGFRegistry::load_from_dir("kgfs")
}

///|
fn declaration_names(decls : Array[PubDeclaration]) -> Map[String, Bool] {
  let names : Map[String, Bool] = {}
  for decl in decls {
    names.set(decl.name, true)
  }
  names
}

///|
test "declarations: RFC 3492 fixture extracts KGF top-level declarations" {
  let path = "fixtures/project/spec-align-rfc3492/typescript/src/punycode.ts"
  let source = @fs.read_file_to_string(path)
  let (decls, _) = extract_pub_declarations_and_doc_map(
    source,
    path,
    Some(registry()),
  )
  let names = declaration_names(decls)
  assert_true(decls.length() >= 10)
  assert_true(names.contains("bootstringParameters"))
}

///|
test "declarations: RFC 2795 fixture extracts KGF top-level declarations" {
  let path = "fixtures/project/spec-align-rfc2795/typescript/src/keeper.ts"
  let source = @fs.read_file_to_string(path)
  let (decls, _) = extract_pub_declarations_and_doc_map(
    source,
    path,
    Some(registry()),
  )
  let names = declaration_names(decls)
  assert_true(decls.length() >= 18)
  assert_false(names.contains("keeperExchangeExample"))
  assert_false(names.contains("chimpSessionExample"))
  assert_false(names.contains("iambPentSessionExample"))
  assert_false(names.contains("panSessionExample"))
  assert_false(names.contains("ChimpCommand"))
  assert_false(names.contains("PanCommand"))
}
