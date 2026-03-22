# filter

## API

- **`should_include`** (Function) — Check if a path should be included based on filter configuration.
- **`dir_could_contain_pattern_match`** (Function) — Check if a directory could contain files that match a path pattern.
- **`should_skip_dir`** (Function) — Check if a directory should be skipped during traversal.
- **`check_ignore_patterns`** (Function) — Check ignore patterns with proper negation handling.
- **`extract_pattern_prefix`** (Function) — Extract the fixed prefix of a glob pattern (before any wildcards).
- **`with_gitignore_from_dir`** (Function) — Load gitignore from a directory and merge into config.
- **`from_project_root`** (Function) — Load FilterConfig from project root, reading gitignore and indexionignore.
- **`with_user_patterns`** (Function) — Create a FilterConfig with user-specified include/exclude patterns.
- **`contains_slash`** (Function) — Check if string contains a slash (but not just at the end).
- **`with_indexionignore_from_dir`** (Function) — Load indexionignore from a directory and merge into config.
- **`is_included`** (Function) — Check if the result indicates the path should be included.
- **`load_ignore_from_file`** (Function) — Load ignore patterns from a specific file in a directory.
- **`load_project_ignores`** (Function) — Load all ignore patterns for a project directory.
- **`parse_ignore_file`** (Function) — Parse an ignore file content (gitignore syntax).
- **`new`** (Function) — Create a new FilterConfig with default settings.

And 39 more symbols.
