///|
test "kneedle: empty and single" {
  assert_eq(kneedle_threshold_index([]), 0)
  assert_eq(kneedle_threshold_index([1.0]), 1)
}

///|
test "kneedle: two items" {
  // Close weights → keep both
  assert_eq(kneedle_threshold_index([1.0, 0.8]), 2)
  // Distant weights → keep only first
  assert_eq(kneedle_threshold_index([1.0, 0.1]), 1)
}

///|
test "kneedle: equal weights" {
  assert_eq(kneedle_threshold_index([5.0, 5.0, 5.0, 5.0]), 4)
}

///|
test "kneedle: L-shaped curve" {
  // Clear elbow between high-weight items and a flat plateau
  let weights = [10.0, 8.0, 6.0, 1.0, 1.0, 1.0, 1.0, 1.0]
  let cutoff = kneedle_threshold_index(weights)
  // Should cut before the plateau
  assert_true(cutoff >= 2 && cutoff <= 4)
}

///|
test "kneedle: gradual descent" {
  let weights = [10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]
  let cutoff = kneedle_threshold_index(weights)
  // Smooth descent — no strong knee, should keep many
  assert_true(cutoff >= 3)
}

///|
test "kneedle: steep drop then plateau" {
  // Mimics real TF-IDF: few high-weight terms, many at minimum
  let weights : Array[Double] = [
    5.6, 4.6, 4.3, 3.9, 3.9, 3.7, 3.7, 3.4, 3.4, 3.4, 3.4, 3.4, 3.4, 2.4, 2.4, 2.4,
    2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4,
  ]
  let cutoff = kneedle_threshold_index(weights)
  // Should cut at the transition to the 2.4 plateau
  assert_true(cutoff >= 10 && cutoff <= 14)
}
