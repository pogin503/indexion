# config

## API

- **`default_exclude_kinds`** (Function) — Default symbol kinds to exclude from indexing.
- **`default`** (Function) — Default config: TF-IDF, raw embedding, HNSW, internal only.
- **`with_impressions`** (Function) — Config with impressions (best quality, requires LLM).
- **`LlmConfig`** (Struct) — LLM configuration for impression generation.
- **`with_impress_prompt`** (Function) — Set custom system prompt for impressions.
- **`embedding_dim`** (Function) — Get embedding dimension for this config.
- **`EmbeddingSource`** (Enum) — Embedding source for function indexing.
- **`precomputed`** (Function) — Config for precomputed embeddings file.
- **`uses_impressions`** (Function) — Check if this config uses impressions.
- **`is_remote`** (Function) — Check if this config uses remote API.
- **`with_impress_model`** (Function) — Set custom model for impressions.
- **`openai`** (Function) — Default LLM config for OpenAI.
- **`with_prompt`** (Function) — LLM config with custom prompt.
- **`with_model`** (Function) — LLM config with custom model.
- **`DigestConfig`** (Struct) — Unified digest configuration.

And 18 more symbols.
