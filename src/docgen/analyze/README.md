# analyze

## API

- **`analyze_file`** (Function) — Analyze a file and return FileInfo with spec selection.
- **`new`** (Function) — Create a new FileInfo with the given path, language, extension, and spec name.
- **`detect_language`** (Function) — Detect file language using both extension and content analysis (legacy).
- **`to_string`** (Function) — Convert the detected language to its lowercase string identifier.
- **`doc_spec_name`** (Function) — Get the appropriate KGF spec name for documentation extraction.
- **`with_doc`** (Function) — Create a new DocSymbol with an attached documentation string.
- **`detect_from_content`** (Function) — Detect language from file content using signature table.
- **`set_module_doc`** (Function) — Set module-level documentation for a given module path.
- **`add_symbol`** (Function) — Add an extracted documentation symbol to the result.
- **`has_any_pattern`** (Function) — Check if content matches any of the given patterns.
- **`DocSymbol`** (Struct) — A documented symbol extracted from KGF analysis.
- **`extract_extension`** (Function) — Extract file extension from path (without dot).
- **`detect_from_extension`** (Function) — Detect language from file extension (fallback).
- **`get_module_docs`** (Function) — Return all module-level documentation entries.
- **`get_kind`** (Function) — Return the symbol kind (e.g. Function, Class).

And 56 more symbols.
