# pipeline

## API

- **`discover_files`** (Function) — Collect all file paths from given input paths.
- **`load_registry_for_paths`** (Function) — Load only relevant KGF specs from a directory based on discovered file paths.
- **`build_path_signals`** (Function) — Build matching signals from file paths (extensions and basenames).
- **`should_skip_dir`** (Function) — Check if directory should be skipped (hidden, build artifacts, etc.).
- **`KGFIndex`** (Struct) — Index mapping source patterns to KGF file paths.
- **`build_kgf_index`** (Function) — Build KGF index by reading only headers from all KGF files.
- **`load_registry_from_index`** (Function) — Load registry from index, only parsing KGF files that match signals.
- **`get_matching_kgf_paths`** (Function) — Get KGF file paths that match the given signals using the index.
- **`sources_match_signals`** (Function) — Check if any source pattern matches the signals.
- **`extract_extension`** (Function) — Extract file extension from path (with dot).
- **`default`** (Function) — Create default discover options.
- **`extract_basename`** (Function) — Extract file basename from path.
- **`trim_trailing_slash`** (Function) — Trim trailing slash from path.
- **`matches_pattern`** (Function) — Shared glob pattern matching.
- **`DiscoverOptions`** (Struct) — Options for file discovery.

And 17 more symbols.
