///|
/// Common CLI argument parsing utilities.
/// SoT for argument parsing functions used across CLI commands.

///|
/// Extract value after '=' in argument.
/// Example: get_arg_value("--foo=bar", 6) returns "bar"
pub fn get_arg_value(arg : String, prefix_len : Int) -> String {
  let chars = arg.to_array()
  if prefix_len >= chars.length() {
    return ""
  }
  let result : Array[Char] = []
  for i = prefix_len; i < chars.length(); i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result)
}

///|
/// Parse a double from string.
/// Handles negative numbers and decimal points.
pub fn parse_double(s : String) -> Double {
  let chars = s.to_array()
  if chars.length() == 0 {
    return 0.0
  }
  let mut result = 0.0
  let mut decimal_place = 0
  let mut is_negative = false
  let mut i = 0
  if chars[0] == '-' {
    is_negative = true
    i = 1
  }
  while i < chars.length() {
    let c = chars[i]
    if c == '.' {
      decimal_place = 1
    } else if c >= '0' && c <= '9' {
      let digit = (c.to_int() - '0'.to_int()).to_double()
      if decimal_place > 0 {
        let mut divisor = 1.0
        for j = 0; j < decimal_place; j = j + 1 {
          divisor = divisor * 10.0
        }
        result = result + digit / divisor
        decimal_place = decimal_place + 1
      } else {
        result = result * 10.0 + digit
      }
    }
    i = i + 1
  }
  if is_negative { -result } else { result }
}

///|
/// Parse an integer from string.
pub fn parse_int(s : String) -> Int {
  let chars = s.to_array()
  if chars.length() == 0 {
    return 0
  }
  let mut result = 0
  let mut is_negative = false
  let mut i = 0
  if chars[0] == '-' {
    is_negative = true
    i = 1
  }
  while i < chars.length() {
    let c = chars[i]
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
    i = i + 1
  }
  if is_negative { -result } else { result }
}
