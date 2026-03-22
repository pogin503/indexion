# parser

## API

- **`parse_single_action`** (Function) — Parses a single action: kind [implicit_id] key1=val1 key2=val2 ...
- **`parse_semantics`** (Function) — Parses semantics section into rule -> on-blocks mapping.
- **`parse_rules`** (Function) — Parses rule lines into rule name to expression mapping.
- **`parse_ignore`** (Function) — Parses ignore section into list of patterns.
- **`parse_lex`** (Function) — Parses the lex section into token definitions with optional SKIP rules.
- **`parse_attrs`** (Function) — Parses simple one-line attribute actions per rule into structured form.
- **`parse_kgf_header`** (Function) — Fast header-only parsing for filtering specs without full parse.
- **`parse_resolver`** (Function) — Parses resolver block into normalized ResolverSpec.
- **`parse_resolver_with_sources`** (Function) — Parses resolver block with sources from header.
- **`parse_preprocess_fst`** (Function) — Parses preprocess_fst section as JSON (single object or array).
- **`parse_features`** (Function) — Parses feature metadata section into name -> values map.
- **`find_char`** (Function) — Finds the index of a character in a string starting from a position.
- **`extract_sources`** (Function) — Extracts sources from the header.
- **`parse_attr_line`** (Function) — Parses a single attribute line: on RuleName: kind1 key1=val1; kind2; ...
- **`parse_token_rule`** (Function) — Parses a TOKEN rule: TOKEN NAME /pattern/[flags] [strip=N] [skip_value]

And 108 more symbols.
