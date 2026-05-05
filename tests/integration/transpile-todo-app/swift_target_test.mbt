///|
/// Snapshot: typescript todo-app fixture lowered to Swift. Swift's type
/// system overlaps significantly with TypeScript's; the snapshot tracks
/// how much is preserved structurally.
async test "snapshot: ts todo-app -> swift" {
  run_target_snapshot("swift")
}
