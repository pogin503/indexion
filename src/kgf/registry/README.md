# registry

## API

- **`get_project_markers`** (Function) — Get project/root marker patterns derived from loaded KGF specs.
- **`is_file_supported`** (Function) — Check if a file path is supported by any registered spec.
- **`get_external_prefixes`** (Function) — Get all external prefixes (bare_prefix values) from registered specs.
- **`detect_from_path`** (Function) — Detect language from file path.
- **`get_doc_spec_name`** (Function) — Get the doc spec name for a language (returns language-doc if exists, otherwise the language itself).
- **`collect_ignore_patterns`** (Function) — Collect all ignore patterns from loaded KGF specs.
- **`load_from_dir`** (Function) — Load all KGF specs from a directory (recursively including subdirectories).
- **`KGFRegistry`** (Struct) — KGFRegistry holds loaded specs and provides lookup functions.
- **`get_lang_from_ext`** (Function) — Get language name from file extension (with or without dot).
- **`to_specs_map`** (Function) — Get a copy of all loaded specs as language -> spec map.
- **`load_specs_recursive`** (Function) — Recursively load KGF specs from a directory.
- **`extract_extension`** (Function) — Extract file extension from path (with dot).
- **`spec_count`** (Function) — Get total number of registered specs.
- **`supports_ext`** (Function) — Check if an extension is supported.
- **`get_languages`** (Function) — Get all registered language names.

And 22 more symbols.
