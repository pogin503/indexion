///|
test "match_char: literal matching" {
  let result = match_pattern("hello", "hello world", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "hello")
  assert_eq(result.end_pos, 5)
}

///|
test "match_char: literal no match" {
  let result = match_pattern("hello", "world", 0)
  assert_eq(result.matched, false)
}

///|
test "match_char: digit class \\d+" {
  let result = match_pattern("\\d+", "123abc", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "123")
}

///|
test "match_char: word class \\w+" {
  let result = match_pattern("\\w+", "hello_world123 test", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "hello_world123")
}

///|
test "match_char: whitespace \\s+" {
  let result = match_pattern("\\s+", "   hello", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "   ")
}

///|
test "match_char: character class [a-z]+" {
  let result = match_pattern("[a-z]+", "hello123", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "hello")
}

///|
test "match_char: character class [0-9]+" {
  let result = match_pattern("[0-9]+", "12345abc", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "12345")
}

///|
test "match_char: negated character class [^a-z]+" {
  let result = match_pattern("[^a-z]+", "123ABC", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "123ABC")
}

///|
test "match_char: any char .+" {
  let result = match_pattern(".+", "hello\nworld", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "hello")
}

///|
test "match_char: optional quantifier \\d?" {
  let result = match_pattern("\\d?", "abc", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "")
}

///|
test "match_char: case insensitive" {
  let result = match_pattern("hello", "HELLO", 0, case_insensitive=true)
  assert_eq(result.matched, true)
  assert_eq(result.text, "HELLO")
}

///|
test "match_char: complex pattern [a-zA-Z_][a-zA-Z0-9_]*" {
  let result = match_pattern("[a-zA-Z_][a-zA-Z0-9_]*", "myVar123_test", 0)
  assert_eq(result.matched, true)
  assert_eq(result.text, "myVar123_test")
}

///|
test "match_char: unicode escape \\uXXXX" {
  let east = '東'
  inspect(east.to_int(), content="26481") // 0x6771
  let r0 = match_pattern("\\u6771", "東京都", 0)
  inspect(r0.matched, content="true")
  let r1a = match_pattern("[\\u6771]", "東", 0)
  inspect(r1a.matched, content="true")
  let r1 = match_pattern("[\\u4e00-\\u9fff]+", "東京都", 0)
  inspect(r1.matched, content="true")
  inspect(r1.text, content="東京都")
}
