# resolver

## API

- **`query_manifest`** (Function) — Query a manifest file (package.json, Cargo.toml) for an entry point.
- **`to_string`** (Function) — Converts a ResolutionResult to a string for JSON serialization.
- **`apply_single_alias`** (Function) — Applies a single alias pattern to a module path.
- **`query_json_simple`** (Function) — Simple JSON query for common manifest fields.
- **`parse_circular_sentinel`** (Function) — Parses a circular sentinel to extract (from_file, module_path).
- **`relative_path`** (Function) — Computes the relative path from one path to another.
- **`dirname`** (Function) — Returns the directory name of a path.
- **`basename`** (Function) — Returns the base name of a path.
- **`find_last_char`** (Function) — Finds the last occurrence of a character in a string.
- **`find_substring`** (Function) — Finds the position of a substring in a string.
- **`normalize_path`** (Function) — Normalizes a path by removing redundant slashes and resolving . and ..
- **`starts_with_at_arr`** (Function) — Checks if a char array starts with a pattern at a given position.
- **`replace_all`** (Function) — Replaces all occurrences of a substring with another substring.
- **`replace_first`** (Function) — Replaces the first occurrence of a pattern with a replacement.
- **`is_circular_sentinel`** (Function) — Checks if a resolved path is a circular dependency sentinel.

And 60 more symbols.
