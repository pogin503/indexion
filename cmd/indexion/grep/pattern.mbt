///|
/// Token pattern matching engine for KGF-aware grep.

///|
/// A single token matcher in a pattern.
pub enum TokenMatcher {
  /// Match exact token kind (e.g. "KW_fn")
  Kind(String)
  /// Match kind and text (e.g. "Ident:foo")
  KindText(String, String)
  /// Match any single token
  Any
  /// Match zero or more tokens (non-greedy)
  Ellipsis
  /// Negation — match any token except this kind
  Not(String)
}

///|
/// Parse a space-separated pattern string into token matchers.
pub fn parse_pattern(pattern : String) -> Array[TokenMatcher] {
  let matchers : Array[TokenMatcher] = []
  let parts = split_pattern(pattern)
  for part in parts {
    if part == "*" {
      matchers.push(Any)
    } else if part == "..." {
      matchers.push(Ellipsis)
    } else if part.length() > 1 && part[0] == '!' {
      matchers.push(Not(@config.substring_from(part, 1)))
    } else {
      // Check for kind:text pattern
      let colon = find_char(part, ':')
      if colon >= 0 {
        let kind = @config.substring(part, 0, colon)
        let text = @config.substring_from(part, colon + 1)
        matchers.push(KindText(kind, text))
      } else {
        matchers.push(Kind(part))
      }
    }
  }
  matchers
}

///|
/// Split pattern string by spaces, respecting token boundaries.
fn split_pattern(s : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder::new()
  for c in s {
    if c == ' ' || c == '\t' {
      if buf.to_string().length() > 0 {
        parts.push(buf.to_string())
        buf.reset()
      }
    } else {
      buf.write_char(c)
    }
  }
  if buf.to_string().length() > 0 {
    parts.push(buf.to_string())
  }
  parts
}

///|
fn find_char(s : String, target : Char) -> Int {
  let mut i = 0
  for c in s {
    if c == target {
      return i
    }
    i += 1
  }
  -1
}

///|
/// Check if a single token matches a matcher.
fn matches_token(matcher : TokenMatcher, tok : @kgf_types.Tok) -> Bool {
  match matcher {
    Kind(kind) => tok.get_kind() == kind
    KindText(kind, text) => tok.get_kind() == kind && tok.get_text() == text
    Any => true
    Ellipsis => true // Should not be called directly
    Not(kind) => tok.get_kind() != kind
  }
}

///|
/// A match result with position information.
pub struct GrepMatch {
  file : String
  line : Int
  start_tok : Int
  end_tok : Int
  matched_text : String
}

///|
/// Search token stream for pattern matches.
/// Returns all non-overlapping matches.
pub fn find_matches(
  tokens : Array[@kgf_types.Tok],
  matchers : Array[TokenMatcher],
  file : String,
  content : String,
) -> Array[GrepMatch] {
  let results : Array[GrepMatch] = []
  // Build token -> line number mapping
  let token_lines = build_token_lines(tokens)
  // Filter out whitespace/newline tokens for pattern matching
  // but keep track of original indices for position reporting
  let significant : Array[(Int, @kgf_types.Tok)] = []
  for i, tok in tokens {
    let kind = tok.get_kind()
    if kind != "NL" && kind != "WS" && kind != "SKIP" {
      significant.push((i, tok))
    }
  }
  let mut pos = 0
  while pos < significant.length() {
    match try_match_at(significant, matchers, pos) {
      Some(end) => {
        let (start_idx, _) = significant[pos]
        let (end_idx, _) = significant[end - 1]
        let line = if start_idx < token_lines.length() {
          token_lines[start_idx]
        } else {
          1
        }
        let matched = extract_matched_text(
          significant, pos, end, content, token_lines,
        )
        results.push(
          { file, line, start_tok: start_idx, end_tok: end_idx, matched_text: matched },
        )
        pos = end
      }
      None => pos += 1
    }
  }
  results
}

///|
fn build_token_lines(tokens : Array[@kgf_types.Tok]) -> Array[Int] {
  let token_lines : Array[Int] = Array::make(tokens.length(), 1)
  let mut line = 1
  for i, tok in tokens {
    token_lines[i] = line
    if tok.get_kind() == "NL" {
      line += 1
    }
  }
  token_lines
}

///|
/// Try to match the pattern starting at position `pos` in the significant token array.
/// Returns the end position (exclusive) if matched, None otherwise.
fn try_match_at(
  tokens : Array[(Int, @kgf_types.Tok)],
  matchers : Array[TokenMatcher],
  pos : Int,
) -> Int? {
  match_recursive(tokens, matchers, 0, pos)
}

///|
fn match_recursive(
  tokens : Array[(Int, @kgf_types.Tok)],
  matchers : Array[TokenMatcher],
  mat_idx : Int,
  tok_idx : Int,
) -> Int? {
  // All matchers consumed — success
  if mat_idx >= matchers.length() {
    return Some(tok_idx)
  }
  let matcher = matchers[mat_idx]
  match matcher {
    Ellipsis => {
      // Non-greedy: try matching rest at current position first, then expand
      let mut i = tok_idx
      while i <= tokens.length() {
        match match_recursive(tokens, matchers, mat_idx + 1, i) {
          Some(end) => return Some(end)
          None => ()
        }
        i += 1
      }
      None
    }
    _ => {
      if tok_idx >= tokens.length() {
        return None
      }
      let (_, tok) = tokens[tok_idx]
      if matches_token(matcher, tok) {
        match_recursive(tokens, matchers, mat_idx + 1, tok_idx + 1)
      } else {
        None
      }
    }
  }
}

///|
fn extract_matched_text(
  significant : Array[(Int, @kgf_types.Tok)],
  start : Int,
  end : Int,
  _content : String,
  _token_lines : Array[Int],
) -> String {
  let buf = StringBuilder::new()
  for i = start; i < end; i = i + 1 {
    let (_, tok) = significant[i]
    if i > start {
      buf.write_string(" ")
    }
    buf.write_string(tok.get_text())
  }
  buf.to_string()
}
