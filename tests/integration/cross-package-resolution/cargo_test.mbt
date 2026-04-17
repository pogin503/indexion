///|
/// Snapshot for fixtures/project/cargo.
///
/// Exercises the KGF + enrichment pipeline against a representative
/// project layout in this ecosystem; the snapshot locks in every
/// moduleDependsOn edge and verifies the structural-completeness
/// invariant on the serialized graph.
test "snapshot: fixtures/project/cargo" {
  let graph = analyze_fixture("fixtures/project/cargo")
  let actual = snapshot_of(graph)
  let snapshot_path = "tests/integration/cross-package-resolution/cargo.snapshot.json"
  assert_snapshot_matches(snapshot_path, actual)
  assert_eq(count_unresolved_structural(graph), 0)
}
