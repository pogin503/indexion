# features

## API

- **`build_call_target`** (Function) — Build the delegate target string from qualifier + callee tokens.
- **`extract_param_names`** (Function) — Extract parameter names from function signature tokens.
- **`parse_call_args`** (Function) — Parse call arguments. Only allows simple identifier references (with optional TILDE for labeled args).
- **`parse_single_call`** (Function) — Try to parse body tokens as a single call expression.
- **`declaration_kind`** (Function) — Check if a token kind represents a declaration keyword.
- **`is_bare_target`** (Function) — Check if a delegate target has no qualifier (no "." or "::").
- **`find_call_sites`** (Function) — Find call sites of a wrapper function in tokenized source code.
- **`apply_edits`** (Function) — Apply character-offset edits to content string.
- **`is_visibility_keyword`** (Function) — Check if a token kind represents a visibility modifier.
- **`delete_lines`** (Function) — Delete lines from content (1-indexed, inclusive range).
- **`tokens_to_tree_node`** (Function) — Convert token slice to TreeNode for APTED comparison.
- **`extract_functions`** (Function) — Extract functions from tokenized source code.
- **`is_identifier_kind`** (Function) — Check if token kind represents an identifier.
- **`is_disqualifying_keyword`** (Function) — Token kinds that indicate control flow or bindings (non-proxy bodies).
- **`PubDeclaration`** (Struct) — A public declaration extracted from source code via KGF tokenization.

And 60 more symbols.
