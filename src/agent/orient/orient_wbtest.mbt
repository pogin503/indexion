///|
test "agent orient: consumer paths include cli adapters" {
  assert_true(is_consumer_path("cmd/indexion/identity/cli.mbt"))
  assert_true(is_consumer_path("skills/indexion-identity/SKILL.md"))
  assert_false(is_consumer_path("src/identity/audit.mbt"))
  assert_false(is_cli_path("cmd/indexion/plan/reconcile/README.md"))
}

///|
test "agent orient: matched terms use shared tokenizer vocabulary" {
  let terms = task_tokens("identity naming audit")
  let matched = matched_terms(
    terms, "src/identity/audit.mbt builds an identity audit report",
  )
  assert_true(matched.contains("identity"))
  assert_true(matched.contains("audit"))
}
