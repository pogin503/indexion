///|
/// Checks if a character is a whitespace character.
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Checks if a character is a digit.
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Checks if a character is a word character (alphanumeric or underscore).
fn is_word_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_'
}

///|
/// Converts a character to lowercase.
fn to_lower(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    Int::unsafe_to_char(c.to_int() + 32)
  } else {
    c
  }
}

///|
/// Gets a character from a string at the given index safely.
fn get_char_at(s : String, index : Int) -> Char? {
  if index >= 0 && index < s.length() {
    Some(Int::unsafe_to_char(s[index].to_int()))
  } else {
    None
  }
}

///|
/// Builds a char array once for repeated indexed access during matching.
pub fn build_input_chars(input : String) -> Array[Char] {
  let chars : Array[Char] = []
  let len = input.length()
  for i = 0; i < len; i = i + 1 {
    chars.push(Int::unsafe_to_char(input[i].to_int()))
  }
  chars
}

///|
/// Gets a character from prebuilt input chars.
fn get_input_char(input_chars : Array[Char], index : Int) -> Char? {
  if index >= 0 && index < input_chars.length() {
    Some(input_chars[index])
  } else {
    None
  }
}
