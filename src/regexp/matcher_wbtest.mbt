///|
test "matcher: word boundary \\b at start" {
  let result = match_pattern("import\\b", "import foo", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "import")
}

///|
test "matcher: word boundary \\b prevents partial match" {
  let result = match_pattern("import\\b", "importing", 0)
  assert_eq(result.matched, false)
}

///|
test "matcher: word boundary \\b at end of string" {
  let result = match_pattern("test\\b", "test", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "test")
}

///|
test "matcher: word boundary \\b with punctuation" {
  let result = match_pattern("foo\\b", "foo()", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "foo")
}

///|
test "matcher: non-word boundary \\B" {
  let result = match_pattern("port\\B", "importing", 2)
  assert_eq(result.matched, true)
  assert_eq(result.text, "port")
}

///|
test "matcher: non-word boundary \\B fails at boundary" {
  let result = match_pattern("port\\B", "import foo", 2)
  assert_eq(result.matched, false)
}

///|
test "matcher: start anchor ^" {
  let result = match_pattern("^hello", "hello world", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "hello")
  let result2 = match_pattern("^hello", "say hello", 4)
  assert_eq(result2.matched, false)
}

///|
test "matcher: end anchor $" {
  let result = match_pattern("world$", "hello world", 6)
  assert_eq(result.matched, true)
  assert_eq(result.text, "world")
}

///|
test "matcher: multiline ^ after newline" {
  let result = match_pattern("^line2", "line1\nline2", 6)
  assert_eq(result.matched, true)
  assert_eq(result.text, "line2")
}

///|
test "matcher: multiline $ before newline" {
  let result = match_pattern("line1$", "line1\nline2", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "line1")
}

///|
test "matcher: string start \\A" {
  let result = match_pattern("\\Ahello", "hello world", 0)
  assert_eq(result.matched, true)
  let result2 = match_pattern("\\Aline2", "line1\nline2", 6)
  assert_eq(result2.matched, false)
}

///|
test "matcher: string end \\z" {
  let result = match_pattern("world\\z", "hello world", 6)
  assert_eq(result.matched, true)
}

///|
test "matcher: non-greedy quantifier with backtracking" {
  let r1 = match_pattern(".*?\\*", "Hello *", 0)
  assert_eq(r1.matched, true)
  assert_eq(r1.text, "Hello *")
  let r2 = match_pattern("[\\s\\S]*?\\*", "Hello *", 0)
  assert_eq(r2.matched, true)
  assert_eq(r2.text, "Hello *")
  let r3 = match_pattern(".*\\*", "Hello *", 0)
  assert_eq(r3.matched, true)
  assert_eq(r3.text, "Hello *")
}

///|
test "matcher: block comment patterns" {
  let r1 = match_pattern("\\/\\*\\*[\\s\\S]*?\\*\\/", "/** Hello */\nexport", 0)
  assert_eq(r1.matched, true)
  assert_eq(r1.text, "/** Hello */")
  let r2 = match_pattern(
    "\\/\\*[\\s\\S]*?\\*\\/", "/* line1\nline2 */\ncode", 0,
  )
  assert_eq(r2.matched, true)
  assert_eq(r2.text, "/* line1\nline2 */")
  let r3 = match_pattern("\\/\\*[\\s\\S]*?\\*\\/", "/* a */ /* b */", 0)
  assert_eq(r3.matched, true)
  assert_eq(r3.text, "/* a */")
}

///|
test "matcher: positive lookahead (?=...)" {
  let r1 = match_pattern("url(?=\\()", "url(foo)", 0)
  assert_eq(r1.matched, true)
  assert_eq(r1.text, "url")
  let r2 = match_pattern("[a-z]+(?=\\s*=)", "name = value", 0)
  assert_eq(r2.matched, true)
  assert_eq(r2.text, "name")
  let r3 = match_pattern("url(?=\\()", "url foo", 0)
  assert_eq(r3.matched, false)
}

///|
test "matcher: negative lookahead (?!...)" {
  let r1 = match_pattern("\\$(?!\\{)", "$x", 0)
  assert_eq(r1.matched, true)
  assert_eq(r1.text, "$")
  let r2 = match_pattern("\\$(?!\\{)", "${x}", 0)
  assert_eq(r2.matched, false)
  let r3 = match_pattern("\\$(?!\\{)|\\$\\{[^}]*\\}", "$x ${name}", 0)
  assert_eq(r3.matched, true)
  assert_eq(r3.text, "$")
}

///|
test "matcher: lookahead in non-capturing group" {
  let r1 = match_pattern("(?:(?![abc])[a-z])+", "defgh", 0)
  assert_eq(r1.matched, true)
  assert_eq(r1.text, "defgh")
  let r2 = match_pattern("(?:(?![abc])[a-z])+", "deafgh", 0)
  assert_eq(r2.matched, true)
  assert_eq(r2.text, "de")
}
