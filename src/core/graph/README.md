# graph

## API

- **`to_json_string`** (Function) — Convert CodeGraph to JSON string following KGF format.
- **`get_or_add_module`** (Function) — Get an existing module or add a new one.
- **`from_string`** (Function) — Parse a string into an EdgeKind.
- **`get_or_add_symbol`** (Function) — Get an existing symbol or add a new one.
- **`SymbolNode`** (Struct) — Symbol node representing a named entity (function, type, variable, etc.).
- **`CodeGraph`** (Struct) — The main code graph structure containing modules, symbols, and edges.
- **`ModuleNode`** (Struct) — Module node representing a source file or module in the codebase.
- **`Edge`** (Struct) — Edge representing a directed relationship between two nodes.
- **`get_callees`** (Function) — Get callees of a symbol (symbols that this symbol calls).
- **`get_callers`** (Function) — Get callers of a symbol (symbols that call this symbol).
- **`EdgeKind`** (Enum) — Edge kinds representing relationships between nodes.
- **`from_json_string`** (Function) — Parse JSON string to CodeGraph following KGF format.
- **`to_string`** (Function) — Convert EdgeKind to its string representation.
- **`ModuleNote`** (Struct) — Note attached to a module (e.g., module_doc).
- **`get_notes`** (Function) — Get notes of a specific type for a module.

And 32 more symbols.
