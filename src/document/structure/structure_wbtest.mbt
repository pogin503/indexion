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
