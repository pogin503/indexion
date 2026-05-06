///|
test "agent orient: consumer paths include cli adapters" {
  assert_true(is_consumer_path("cmd/indexion/identity/cli.mbt"))
  assert_true(is_consumer_path("cmd/indexion/plan/reconcile/README.md"))
  assert_true(is_consumer_path("skills/indexion-identity/SKILL.md"))
  assert_true(
    is_consumer_path("some/project/skills/indexion-identity/SKILL.md"),
  )
  assert_false(is_consumer_path("src/identity/audit.mbt"))
  assert_false(is_cli_path("cmd/indexion/plan/reconcile/README.md"))
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

///|
test "agent orient: readiness quiz captures owner and forbidden path" {
  let quiz = readiness_quiz(
    [{ path: "src/identity", reason: "owner" }],
    [{ path: "cmd/indexion/identity/cli.mbt", reason: "consumer" }],
    [{ path: "cmd/indexion/identity/cli.mbt", reason: "forbidden" }],
    [{ path: "src/identity/audit.mbt", reason: "read first" }],
  )
  assert_eq(quiz.length(), 3)
  assert_eq(quiz[0].expected_answer, "src/identity")
  assert_eq(quiz[1].expected_answer, "cmd/indexion/identity/cli.mbt")
  assert_eq(quiz[2].expected_answer, "src/identity/audit.mbt")
}

///|
test "agent orient: readiness quiz prefers implementation preflight evidence" {
  let quiz = readiness_quiz(
    [{ path: "src/identity", reason: "owner" }],
    [],
    [{ path: "cmd/indexion/identity/cli.mbt", reason: "forbidden" }],
    [
      { path: "cmd/indexion/main.mbt", reason: "read first" },
      { path: "src/identity/audit.mbt", reason: "read second" },
    ],
  )
  assert_eq(quiz[2].expected_answer, "src/identity/audit.mbt")
}

///|
test "agent orient: consumer dominated terms are not owner query terms" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "cmd/indexion/main.mbt", "h1", "cmd indexion cli", "cmd indexion cli",
    ),
    new_local_file_brief(
      "cmd/indexion/identity/cli.mbt", "h2", "identity cli", "identity cli",
    ),
    new_local_file_brief(
      "skills/skills/indexion-identity/SKILL.md", "h3", "identity cli", "identity cli",
    ),
    new_local_file_brief(
      "src/identity/audit.mbt", "h4", "identity audit", "identity audit",
    ),
  ]
  assert_true(is_consumer_dominated_term("cli", briefs))
  assert_false(is_consumer_dominated_term("identity", briefs))
}

///|
test "agent orient: owner profile uses directory concept text" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "src/agent/orient/orient.mbt", "h1", "agent orient call implementation should render",
      "agent orient call implementation should render",
    ),
    new_local_file_brief(
      "src/identity/README.md", "h2", "src identity readme", "names and content are separate artifacts that drift; score name content divergence",
    ),
    new_local_file_brief(
      "src/identity/types.mbt", "h3", "NameDivergence NamedEntity content name drift",
      "NameDivergence measures whether names still fit content bodies",
    ),
  ]
  let map = build_or_update_orient_map(
    { ..AgentOrientConfig::default(), no_update: false },
    briefs,
    None,
  )
  let task = "detect drift between names and implementation contents"
  let terms = owner_task_terms_for_task(task, task_tokens(task), map)
  assert_true(terms.contains("content"))
  assert_true(terms.contains("name"))
  let owners = likely_owners(map, terms, task, 3)
  assert_eq(owners[0].path, "src/identity")
}

///|
test "agent orient: wiki sources do not smear parent pages into children" {
  assert_true(source_matches_owner("src/similarity/", "src/similarity"))
  assert_true(
    source_matches_owner(
      "src/similarity/apted/algorithm.mbt", "src/similarity/apted",
    ),
  )
  assert_false(source_matches_owner("src/similarity/", "src/similarity/apted"))
  assert_true(
    wiki_page_is_owner_specific({
      id: "owner",
      title: "Owner",
      file: "owner.md",
      sources: ["src/identity/"],
    }),
  )
  assert_false(
    wiki_page_is_owner_specific({
      id: "hub",
      title: "Hub",
      file: "hub.md",
      sources: ["src/kgf/", "src/core/graph/", "src/digest/"],
    }),
  )
}

///|
test "agent orient: owner terms prefer objective over infrastructure constraints" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "src/core/graph/README.md", "h1", "code graph codebase search reconcile wiki infrastructure",
      "CodeGraph represents a codebase as modules, symbols, names, content, and edges. Reconcile commands consume the graph.",
    ),
    new_local_file_brief(
      "src/identity/README.md", "h2", "identity name content drift", "Names and content are separate artifacts that drift. This package measures whether a name still fits its content.",
    ),
  ]
  let map = build_or_update_orient_map(
    { ..AgentOrientConfig::default(), no_update: false },
    briefs,
    None,
  )
  let task = "Build a codebase tool that detects drift between names and implementation contents. Reuse existing graph, search, wiki, and reconcile infrastructure."
  let terms = owner_task_terms_for_task(task, task_tokens(task), map)
  assert_false(terms.contains("graph"))
  assert_false(terms.contains("search"))
  let owners = likely_owners(map, terms, task, 2)
  assert_eq(owners[0].path, "src/identity")
}
