# manage

## API

- **`derive_category`** (Function) — Derive category from relative path between file and kgfs root.
- **`list_installed_specs`** (Function) — List all installed specs with metadata.
- **`find_spec_in_tree`** (Function) — Search the GitHub tree API response for a file matching the target filename.
- **`find_extracted_dir`** (Function) — Find the extracted directory inside the temp dir (GitHub tarball prefix).
- **`collect_specs_recursive`** (Function) — Recursively scan directory for .kgf files and extract metadata.
- **`extract_spec_info`** (Function) — Extract spec metadata from a .kgf file using header-only parse.
- **`check_status`** (Function) — Validate HTTP response status, raising on non-200.
- **`github_headers`** (Function) — Common HTTP headers for GitHub API requests.
- **`to_string`** (Function) — Format error as human-readable string.
- **`KgfSpecInfo`** (Struct) — Metadata about an installed KGF spec.
- **`sort_specs`** (Function) — Sort specs by category then name.

And 29 more symbols.
