///|
/// Cross-package resolution snapshot for the MoonBit fixture
/// (fixtures/project/moonbit).
///
/// Exercises: moon.pkg alias capture, @alias source-file usage, project-
/// source-dir ("src") resolution, bare_prefix canonicalization.
test "snapshot: fixtures/project/moonbit" {
  let graph = analyze_fixture("fixtures/project/moonbit")
  let actual = snapshot_of(graph)
  let snapshot_path = "tests/integration/cross-package-resolution/moonbit.snapshot.json"
  assert_snapshot_matches(snapshot_path, actual)
  assert_eq(count_unresolved_structural(graph), 0)
}
