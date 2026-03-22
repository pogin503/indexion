///|
test "solid: from_matches splits comma-separated source directories via common parser" {
  let cmd = command()
  let matches = cmd.parse(argv=["--from=apps/web, apps/admin ,pkg/shared"][:])
  let config = SolidConfig::from_matches(matches)
  assert_eq(config.from_dirs, ["apps/web", "apps/admin", "pkg/shared"])
}

///|
test "solid: categorize_matches uses shared path scope matching" {
  let matches : Array[FileMatch] = [
    {
      _source1: "web:src/http/api.ts",
      _source2: "admin:src/http/api.ts",
      similarity: 1.0,
      relative_path: "src/http/api.ts",
      _matched_rule: None,
    },
  ]
  let rules : Array[SolidRule] = [
    { pattern: "src/**/api.[tj]s", target: "shared/http/" },
  ]
  let categorized = categorize_matches(matches, rules, "components")
  assert_eq(categorized.unmatched.length(), 0)
  assert_true(categorized.by_target.get("components/shared/http/") is Some(_))
}
