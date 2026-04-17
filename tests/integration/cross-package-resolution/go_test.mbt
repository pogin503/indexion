///|
/// Snapshot for fixtures/project/go.
///
/// Exercises the KGF + enrichment pipeline against a representative
/// project layout in this ecosystem; the snapshot locks in every
/// moduleDependsOn edge and verifies the structural-completeness
/// invariant on the serialized graph.
test "snapshot: fixtures/project/go" {
  let graph = analyze_fixture("fixtures/project/go")
  let actual = snapshot_of(graph)
  let snapshot_path = "tests/integration/cross-package-resolution/go.snapshot.json"
  assert_snapshot_matches(snapshot_path, actual)
  assert_eq(count_unresolved_structural(graph), 0)
}
