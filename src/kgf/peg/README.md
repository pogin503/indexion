# peg

## API

- **`compute_brace_pairs`** (Function) — Computes bracket pairs from tokens in O(n).
- **`CompiledNode`** (Enum) — CompiledNode is an ID-based representation for evaluation hot paths.
- **`Labels`** (Enum) — Lazy labels: defer Map creation until actually needed.
- **`FastCompiledNode`** (Enum) — FastCompiledNode separates tokens and rules for O(1) matching.
- **`get_close`** (Function) — Gets the matching close bracket position for an open bracket.
- **`parse_choice`** (Function) — Parses a choice expression (alternatives separated by / or |).
- **`merge_into_map`** (Function) — Merges labels into a target Map (in place).
- **`parse_primary`** (Function) — Parses a primary expression (identifier, label, parenthesized group, bracketed optional, or predicate).
- **`parse_expr_with_warnings`** (Function) — Parses a PEG expression string into a Node AST, returning deprecation warnings.
- **`WorkItem`** (Enum) — Work item for the evaluation stack.
- **`BracePairs`** (Struct) — BracePairs maps opening bracket positions to closing bracket positions.
- **`MemoState`** (Enum) — Memo entry states for memoization.
- **`compile_node`** (Function) — Compiles an AST node into ID-based node table for faster evaluation.
- **`is_stop_token`** (Function) — Returns true if current token is a stop token (RP, RB, BAR, SLASH).
- **`is_and`** (Function) — Returns true if this node is an And predicate (positive lookahead).

And 195 more symbols.
