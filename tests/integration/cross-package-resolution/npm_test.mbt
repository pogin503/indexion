///|
/// Cross-package resolution snapshot for the npm fixture
/// (fixtures/project/npm).
///
/// Locks in:
///   * every `moduleDependsOn` edge produced for a TS/JS package,
///   * the set of discovered modules (canonicalization inputs + outputs),
///   * the structural-completeness invariant (no dangling endpoints).
test "snapshot: fixtures/project/npm" {
  let graph = analyze_fixture("fixtures/project/npm")
  let actual = snapshot_of(graph)
  let snapshot_path = "tests/integration/cross-package-resolution/npm.snapshot.json"
  assert_snapshot_matches(snapshot_path, actual)
  // Redundant but explicit: the structural invariant is part of the contract
  // we want future refactors to preserve.
  assert_eq(count_unresolved_structural(graph), 0)
}
