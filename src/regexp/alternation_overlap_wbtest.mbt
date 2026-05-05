// Regression tests for the alternation-overlap bug in match_alternation
// and enumerate_group_end_positions.
//
// Background
// ----------
// Alternation `(a|b|c)` is parsed into a Group whose only element is an
// Alternation. The matcher used to commit to the first matching alternative
// and only return its end position, even when the surrounding context
// (e.g. a trailing `\b`) failed at that position and a longer alternative
// would have succeeded. As a result, `\b(you|your)\b` against "your"
// returned no match: `you` matched at length 3 but `\b` failed at the `r`,
// and the engine never reconsidered `your` (length 4).
//
// The fix surfaces every alternative's end position from
// try_collect_repeat_positions_fast and enumerate_group_end_positions, so
// the outer backtracking can try each in turn. These tests pin the fix and
// guard against regressions in either path.

///|
test "alternation: 2-alt overlap, shorter first, literal" {
  // Regression: `\b(you|your)\b` against "your". Bug previously returned
  // `false` because `you` matched first and `\b` failed at offset 3.
  let r = match_pattern("\\b(you|your)\\b", "your", 0)
  assert_true(r.matched)
  assert_eq(r.text, "your")
}

///|
test "alternation: 2-alt overlap, shorter first, char class" {
  let r = match_pattern("\\b([Yy]ou|[Yy]our)\\b", "your", 0)
  assert_true(r.matched)
  assert_eq(r.text, "your")
  let r2 = match_pattern("\\b([Yy]ou|[Yy]our)\\b", "Your", 0)
  assert_true(r2.matched)
  assert_eq(r2.text, "Your")
}

///|
test "alternation: 3-alt overlap, prefix sequence, literal" {
  // (I|you|your) — `I` and `you` both prefix-match before `your`.
  let r = match_pattern("\\b(I|you|your)\\b", "your", 0)
  assert_true(r.matched)
  assert_eq(r.text, "your")
}

///|
test "alternation: 3-alt overlap, prefix sequence, char class" {
  let r = match_pattern("\\b(I|[Yy]ou|[Yy]our)\\b", "your", 0)
  assert_true(r.matched)
  assert_eq(r.text, "your")
}

///|
test "alternation: longer-first ordering already worked" {
  // Sanity: when the longer alternative comes first the bug was hidden,
  // so this case succeeded both before and after the fix.
  let r = match_pattern("\\b(your|you)\\b", "your", 0)
  assert_true(r.matched)
  assert_eq(r.text, "your")
}

///|
test "alternation: shorter form still matches when standalone" {
  // After the fix, `you` standing alone must still match — we should
  // surface every alternative's end position, not silently bias toward
  // the longest.
  let r = match_pattern("\\b(you|your)\\b", "you only", 0)
  assert_true(r.matched)
  assert_eq(r.text, "you")
}

///|
test "alternation: char class as the only alternative" {
  let r = match_pattern("\\b([Yy]our)\\b", "your", 0)
  assert_true(r.matched)
  let r2 = match_pattern("\\b([Yy]our)\\b", "Your", 0)
  assert_true(r2.matched)
}
