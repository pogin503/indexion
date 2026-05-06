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
    [],
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
  let terms = owner_task_terms_from_map(task_tokens(task), map)
  if !terms.contains("content") {
    fail("profile terms=" + terms.join(","))
  }
  let owners = likely_owners(map, terms, task, 3)
  if owners[0].path != "src/identity" {
    fail("profile terms=" + terms.join(",") + " owner=" + owners[0].path)
  }
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
test "agent orient: owner query uses provided objective gloss" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "src/search/README.md", "h1", "search grep graph wiki reconcile cli", "Search infrastructure indexes graph, grep, wiki, and reconcile corpora for codebase lookup.",
    ),
    new_local_file_brief(
      "src/identity/README.md", "h2", "identity name content drift", "Names and content are separate artifacts that drift. This package scores whether implementation contents still fit file, folder, and function names.",
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
  let task = "name/content drift scoring and remediation planning"
  let terms = owner_task_terms_from_map(task_tokens(task), map)
  assert_true(terms.contains("content"))
  let owners = likely_owners(map, terms, task, 2)
  if owners[0].path != "src/identity" {
    fail("gloss terms=" + terms.join(",") + " owner=" + owners[0].path)
  }
}

///|
test "agent orient: documentation-only paths remain knowledge sources" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "RELEASE_NOTES.md", "h1", "name content drift scoring planning", "Release notes mention name/content drift scoring and remediation planning.",
    ),
    new_local_file_brief(
      "wiki/Home.md", "h2", "name content drift scoring planning", "Wiki overview mentions name/content drift scoring and remediation planning.",
    ),
    new_local_file_brief(
      "src/identity/README.md", "h3", "identity name content drift", "Names and content drift apart. Identity scores whether implementation contents still fit names.",
    ),
    new_local_file_brief(
      "src/identity/types.mbt", "h4", "NameDivergence NamedEntity content name drift",
      "NameDivergence measures whether names still fit content bodies",
    ),
  ]
  let map = build_or_update_orient_map(
    { ..AgentOrientConfig::default(), no_update: false },
    briefs,
    None,
  )
  assert_true(owner_path_exists(map, "RELEASE_NOTES.md"))
  assert_true(owner_path_exists(map, "wiki"))
  let task = "name/content drift scoring and remediation planning"
  let terms = owner_task_terms_from_map(task_tokens(task), map)
  let owners = likely_owners(map, terms, task, 2)
  assert_eq(owners[0].path, "src/identity")
  let knowledge = likely_knowledge_sources(map, terms, task, 2)
  assert_true(
    knowledge[0].path == "RELEASE_NOTES.md" || knowledge[0].path == "wiki",
  )
}

///|
test "agent orient: preflight leads with initial owner evidence" {
  let briefs : Array[LocalFileBrief] = [
    new_local_file_brief(
      "skills/skills/indexion-agent-orient/SKILL.md", "h1", "agent orient thin cli reconcile search graph",
      "Agent orientation skill tells consumers to run graph search and reconcile before editing CLI.",
    ),
    new_local_file_brief(
      "src/identity/README.md", "h2", "identity name content drift", "Names and content drift apart. Identity scores whether names still fit implementation contents.",
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
  let task = "name/content drift scoring"
  let terms = owner_task_terms_from_map(task_tokens(task), map)
  let owners = likely_owners(map, terms, task, 2)
  assert_eq(owners[0].path, "src/identity")
  assert_true(
    owners[0].reason.contains("Initial implementation-owner hypothesis"),
  )
  let scored = score_briefs(briefs, task_tokens(task), task)
  scored.sort_by(fn(a, b) { b.score.compare(a.score) })
  let preflight = required_preflight(map, owners, scored, 3)
  assert_eq(preflight[0].path, "src/identity/README.md")
  assert_true(preflight[0].reason.contains("confirm the likely owner"))
}

///|
fn owner_path_exists(map : AgentOrientMap, path : String) -> Bool {
  for owner in map.owners {
    if owner.path == path {
      return true
    }
  }
  false
}
