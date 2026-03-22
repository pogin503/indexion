# index

## API

- **`TfidfEmbeddingProvider`** (Struct) — TF-IDF based embedding provider.
- **`remote`** (Function) — Configuration for remote embeddings (OpenAI text-embedding-3-small).
- **`query_with_remote`** (Function) — Query using remote embeddings (requires embedding in query itself).
- **`default`** (Function) — Default configuration: TF-IDF with 256 dimensions and HNSW.
- **`build_vocabulary`** (Function) — Build vocabulary from a corpus of texts.
- **`BuildResult`** (Struct) — Result of building/updating the index.
- **`DigestIndex`** (Struct) — DigestIndex - Main index structure.
- **`ln`** (Function) — Natural logarithm approximation.
- **`serialize`** (Function) — Serialize index for persistence.
- **`stats`** (Function) — Get statistics about the index.
- **`IndexConfig`** (Struct) — Configuration for DigestIndex.
- **`new`** (Function) — Create an empty BuildResult.
- **`embed`** (Function) — Generate embedding for text.
- **`query`** (Function) — Query by purpose text.

And 14 more symbols.
