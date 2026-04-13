///|
test "api: find_pattern_captures returns groups" {
  let matches = find_pattern_captures("(foo)=(\\d+)", "foo=10\nfoo=20")
  assert_eq(matches.length(), 2)
  assert_eq(matches[0].text, "foo=10")
  assert_eq(matches[0].captures, ["foo", "10"])
  assert_eq(matches[1].captures, ["foo", "20"])
}

///|
test "api: find_pattern_captures supports case insensitive" {
  let matches = find_pattern_captures(
    "(reserved)",
    "RESERVED reserved",
    case_insensitive=true,
  )
  assert_eq(matches.length(), 2)
  assert_eq(matches[0].captures[0], "RESERVED")
  assert_eq(matches[1].captures[0], "reserved")
}

///|
test "api: capture literals from normative lines" {
  let content = "## Timeout\nThe value MUST be `36`.\nFor example, `99` is shown.\nThe response SHALL return `200`.\n"
  let numeric = find_pattern_captures(
    "^(?![^\\n]*(?:for example|e\\.g\\.|suppose|consider ))[^\\n]*(?:\\bmust\\b|\\bshall\\b|\\bshould\\b|\\brequired\\b|=|\\|)[^\\n]*\\b([0-9]{1,})\\b",
    content,
    case_insensitive=true,
  )
  let quoted = find_pattern_captures(
    "^(?![^\\n]*(?:for example|e\\.g\\.|suppose|consider ))[^\\n]*(?:\\bmust\\b|\\bshall\\b|\\bshould\\b|\\brequired\\b|=|\\|)[^\\n]*`([^`\\n]+)`",
    content,
    case_insensitive=true,
  )
  assert_eq(numeric.map(fn(m) { m.captures[0] }), ["36", "200"])
  assert_eq(quoted.map(fn(m) { m.captures[0] }), ["36", "200"])
}

///|
test "api: capture section refs and pipe table pairs" {
  let content = "6. CHIMP Specification\nSee sections 6.1 and 6.2.\n| 7 | REQUEST_STOP |\n"
  let refs1 = find_pattern_captures(
    "^((?:[A-Z]|\\d+(?:\\.\\d+)*))\\.?[ \\t]",
    content,
    case_insensitive=true,
  )
  let refs2 = find_pattern_captures(
    "\\bsections?\\s+((?:[A-Z]|\\d+(?:\\.\\d+)*))\\.?\\b",
    content,
    case_insensitive=true,
  )
  let refs3 = find_pattern_captures(
    "\\b(?:and|or)\\s+((?:[A-Z]|\\d+(?:\\.\\d+)*))\\.?\\b",
    content,
    case_insensitive=true,
  )
  let pairs = find_pattern_captures(
    "\\|\\s*([0-9]+(?:\\.[0-9]+)*)\\s*\\|\\s*([A-Za-z][A-Za-z0-9 /'_-]*[A-Za-z0-9/_-])\\s*\\|",
    content,
  )
  assert_eq(refs1.map(fn(m) { m.captures[0] }), ["6"])
  assert_eq(refs2.map(fn(m) { m.captures[0] }), ["6.1"])
  assert_eq(refs3.map(fn(m) { m.captures[0] }), ["6.2"])
  assert_eq(pairs.length(), 1)
  assert_eq(pairs[0].captures, ["7", "REQUEST_STOP"])
}

///|
test "api: matches_at convenience" {
  assert_eq(matches_at("\\d+", "abc123", 3), true)
  assert_eq(matches_at("\\d+", "abc123", 0), false)
}

///|
test "api: compile_pattern returns None for invalid" {
  // Unclosed character class
  let result = compile_pattern("[abc")
  assert_true(result is None)
}

///|
test "api: find_pattern_captures empty input" {
  let matches = find_pattern_captures("\\d+", "")
  assert_eq(matches.length(), 0)
}

///|
test "api: find_pattern_captures no match" {
  let matches = find_pattern_captures("\\d+", "abc def")
  assert_eq(matches.length(), 0)
}

///|
test "api: find_pattern_captures multiple non-overlapping" {
  let matches = find_pattern_captures("\\d+", "a1b22c333d")
  assert_eq(matches.length(), 3)
  assert_eq(matches[0].text, "1")
  assert_eq(matches[1].text, "22")
  assert_eq(matches[2].text, "333")
}
