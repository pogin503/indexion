# types

## API

- **`Impression`** (Struct) — Impression represents LLM-generated or extracted purpose description.
- **`EmbeddingProvider`** (Trait) — EmbeddingProvider trait defines the interface for text-to-vector conversion.
- **`FunctionUnit`** (Struct) — FunctionUnit encapsulates a function with its context.
- **`FunctionHash`** (Struct) — Hash of function content (SHA-256 truncated to 32 hex characters).
- **`load_from_file`** (Function) — Load embeddings from JSONL file.
- **`from_summary`** (Function) — Create an Impression from just a summary (auto-extract keywords later).
- **`parse_embedding_line`** (Function) — Parse a single embedding line: {"id": "...", "embedding": [...]}
- **`RemoteEmbeddingProvider`** (Struct) — Remote embedding provider that loads pre-computed embeddings.
- **`get`** (Function) — Get embedding for a text (must be pre-computed and loaded).
- **`is_leaf`** (Function) — Check if this is a leaf function (no outgoing calls).
- **`to_text`** (Function) — Get the full text representation for embedding.
- **`QueryHit`** (Struct) — Query hit result from purpose-based search.
- **`from_string`** (Function) — Create a FunctionHash from a string value.
- **`with_impression`** (Function) — Create a FunctionUnit with an impression.
- **`id`** (Function) — Get the function ID (same as symbol ID).

And 37 more symbols.
