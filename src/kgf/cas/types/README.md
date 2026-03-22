# types

## API

- **`ModuleChunk`** (Struct) — A chunk represents a single module's contribution to the graph.
- **`SymbolicRef`** (Struct) — A symbolic reference to an external module (not yet resolved).
- **`ContentHash`** (Struct) — Content hash (SHA-256 truncated to 32 hex characters).
- **`CASManifest`** (Struct) — Root manifest for a KGF CAS store.
- **`with_spec_hash`** (Function) — Create a new CASManifest with new spec hash (clears modules).
- **`from_string`** (Function) — Create a ContentHash from a String (no validation).
- **`with_modules`** (Function) — Create a new CASManifest with updated modules.
- **`add_external_ref`** (Function) — Add an external reference to the chunk.
- **`to_string`** (Function) — Get the ContentHash value as a String.
- **`new`** (Function) — Create a new SymbolicRef.

And 17 more symbols.
