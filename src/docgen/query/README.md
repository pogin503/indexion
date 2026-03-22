# query

## API

- **`CircularDep`** (Struct) — Circular dependency information extracted from CircularDependency edges.
- **`TypeRelation`** (Struct) — Type hierarchy relationship extracted from Extends/Implements edges.
- **`ModuleDep`** (Struct) — Module dependency information extracted from ModuleDependsOn edges.
- **`get_ref_site`** (Function) — Get the reference site (where the symbol is used).
- **`SymbolRef`** (Struct) — Symbol reference extracted from References edges.
- **`get_dep_kind`** (Function) — Get the dependency kind (import, require, etc).
- **`CallInfo`** (Struct) — Call relationship extracted from Calls edges.
- **`get_relation`** (Function) — Get the relation type (extends, implements).
- **`get_ref_kind`** (Function) — Get the reference kind (call, access, etc).
- **`get_kind`** (Function) — Get the symbol kind (Function, Class, etc).
- **`get_doc`** (Function) — Get the documentation comment (if any).
- **`SymbolDecl`** (Struct) — Symbol declaration with documentation.
- **`get_via`** (Function) — Get the intermediate module (if any).
- **`get_file`** (Function) — Get the file where the call occurs.
- **`get_symbol`** (Function) — Get the referenced symbol ID.

And 30 more symbols.
