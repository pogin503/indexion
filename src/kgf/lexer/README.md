# lexer

## API

- **`new`** (Function) — Creates a new Lexer with the given token definitions.
- **`match_pattern`** (Function) — Matches a pattern against the input starting at the given position.
- **`matches_at`** (Function) — Checks if a pattern matches at the start of the input at the given position.
- **`tokenize`** (Function) — Tokenizes the input string and returns an array of tokens.
- **`match_quantified`** (Function) — Matches a quantified element against the input starting at pos.
- **`try_match`** (Function) — Tries to match a token at the given position.
- **`extract_value`** (Function) — Extracts the value from a token text.
- **`is_word_char`** (Function) — Checks if a character is a word character (alphanumeric or underscore).
- **`build_input_chars`** (Function) — Builds a char array once for repeated indexed access during matching.
- **`is_at_word_boundary_with_chars`** (Function) — Checks if position is at a word boundary using prebuilt input chars.
- **`CompiledPattern`** (Struct) — CompiledPattern stores parsed regex elements for repeated matching.
- **`match_compiled_end_pos_with_chars`** (Function) — Matches a compiled pattern against the input at the given position.
- **`match_compiled_with_chars`** (Function) — Matches a compiled pattern against the input at the given position.
- **`has_case_insensitive_flag`** (Function) — Returns true when regex flags include case-insensitive matching.
- **`parse_pattern`** (Function) — Parses the pattern string into a list of quantified elements.

And 75 more symbols.
