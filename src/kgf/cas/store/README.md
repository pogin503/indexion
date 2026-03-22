# store

## API

- **`MemoryChunkStore`** (Struct) — In-memory chunk store implementation.
- **`find_orphans`** (Function) — Find orphaned chunks (chunks not referenced in a set of known hashes).
- **`clean_orphans`** (Function) — Clean up orphaned chunks.
- **`ChunkStore`** (Trait) — Chunk store trait for reading/writing module chunks.
- **`size`** (Function) — Get the number of chunks in the store.
- **`new`** (Function) — Create a new in-memory chunk store.
- **`clear`** (Function) — Clear all chunks from the store.
- **`list`** (Function) — List all chunk hashes.

And 5 more symbols.
