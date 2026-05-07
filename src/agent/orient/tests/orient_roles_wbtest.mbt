///|
test "agent orient: roles come from file metadata and content signals" {
  assert_eq(
    infer_file_role(
      {
        path: "tools/frontdoor.mbt",
        content: "",
        language: "moonbit",
        content_type: None,
      },
      task_tokens("function build_command command option dispatch"),
      task_tokens("argparse command options dispatch"),
      1,
      0,
      external_terms=["argparse"],
    ),
    "cli-consumer",
  )
  assert_eq(
    infer_file_role(
      {
        path: "guides/agent-setup.md",
        content: "",
        language: "markdown",
        content_type: Some("document"),
      },
      [],
      task_tokens("agent workflow command prompt"),
      0,
      0,
    ),
    "consumer",
  )
  assert_eq(
    infer_file_role(
      {
        path: "src/identity/audit.mbt",
        content: "",
        language: "moonbit",
        content_type: None,
      },
      task_tokens("function audit_name_content"),
      task_tokens("identity audit implementation"),
      0,
      1,
    ),
    "implementation",
  )
}

///|
test "agent orient: matched terms use shared tokenizer vocabulary" {
  let terms = task_tokens("identity naming audit")
  let matched = matched_terms_in_tokens(
    terms,
    task_tokens("src/identity/audit.mbt builds an identity audit report"),
  )
  assert_true(matched.contains("identity"))
  assert_true(matched.contains("audit"))
}
