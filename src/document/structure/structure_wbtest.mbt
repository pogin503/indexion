///|
fn test_registry() -> @kgf_registry.KGFRegistry {
  @kgf_registry.KGFRegistry::load_from_dir("kgfs")
}

///|
test "markdown heading level comes from kgf semantics" {
  let content =
    #|# Title
    #|
    #|## Details
    #|Body
  let sections = load_document_sections(
    content,
    "README.md",
    Some(test_registry()),
  )
  assert_eq(sections.length(), 2)
  assert_eq(sections[0].level, Some(1))
  assert_eq(sections[1].level, Some(2))
}

///|
test "sdd numbered requirement emits requirement and scenario facts" {
  let registry = test_registry()
  let spec = match registry.get_spec("sdd-numbered-requirement") {
    Some(value) => value
    None => fail("missing sdd-numbered-requirement")
  }
  let content =
    #|## Requirement 1: Session Timeout
    #|The system SHALL expire sessions after 15 minutes.
    #|
    #|### Scenario: Session expires
    #|- GIVEN an authenticated session
    #|- WHEN 15 minutes pass without activity
    #|- THEN the session is invalidated
  let interpreted = interpret_document(content, "/tmp/spec.md", spec)
  let kinds = interpreted.facts.map(fn(fact) { fact.kind })
  assert_true(kinds.contains("document_requirement"))
  assert_true(kinds.contains("document_scenario"))
}

///|
test "rfc plaintext emits section roles for references and examples" {
  let registry = test_registry()
  let spec = match registry.get_spec("rfc-plaintext") {
    Some(value) => value
    None => fail("missing rfc-plaintext")
  }
  let content =
    #|9. References
    #|RFC 2119.
    #|
    #|10. Acknowledgements
    #|Thanks.
    #|
    #|8.4 Example ZOO-to-CRITIC Session using PAN
    #|SanDiego> TRANSCRIPT RomeoAndJuliet.BoBo.763 251
  let interpreted = interpret_document(content, "/tmp/rfc2795.rfc.txt", spec)
  let roles : Array[String] = []
  for fact in interpreted.facts {
    if fact.kind != "document_section_role" {
      continue
    }
    match fact.payload.get("role") {
      Some(String(value)) => roles.push(value)
      _ => ()
    }
  }
  assert_true(roles.contains("reference"))
  assert_true(roles.contains("meta"))
  assert_true(roles.contains("example"))
}

///|
test "document semantics emit literals without illustrative examples" {
  let registry = test_registry()
  let spec = match registry.get_spec("markdown") {
    Some(value) => value
    None => fail("missing markdown")
  }
  let content =
    #|## Timeout
    #|The value MUST be `36`.
    #|For example, `99` is shown in Appendix A.
    #|The response SHALL return `200`.
  let interpreted = interpret_document(content, "/tmp/spec.md", spec)
  let literals = literals_for_line(interpreted, 1)
  assert_true(literals.contains("36"))
  assert_true(literals.contains("200"))
  assert_false(literals.contains("99"))
}

///|
test "document semantics emit section refs and table pairs" {
  let registry = test_registry()
  let spec = match registry.get_spec("rfc-plaintext") {
    Some(value) => value
    None => fail("missing rfc-plaintext")
  }
  let content =
    #|6. CHIMP Specification
    #|See sections 6.1 and 6.2.
    #|| 7 | REQUEST_STOP |
  let interpreted = interpret_document(content, "/tmp/rfc2795.rfc.txt", spec)
  let refs = section_refs_for_line(interpreted, 1)
  let pairs = table_pairs_for_line(interpreted, 1)
  assert_true(refs.contains("6"))
  assert_true(refs.contains("6.1"))
  assert_true(refs.contains("6.2"))
  assert_true(pairs.contains({ label: "REQUEST_STOP", literal: "7" }))
}
