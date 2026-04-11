# config

## API

- **`resolve_provider`** (Function) — Resolve an EmbeddingProvider from named CLI/config parameters.
- **`to_json`** (Function) — Serialize EmbeddingProvider to JSON.
- **`sanitize_provider_key`** (Function) — Sanitize a string for use as a provider key (filesystem-safe).
- **`ProviderConfig`** (Struct) — Per-provider configuration.
- **`from_json`** (Function) — Deserialize EmbeddingProvider from JSON.
- **`remote`** (Function) — Create a remote provider config from an EmbeddingApiConfig.
- **`EmbeddingProvider`** (Enum) — Embedding provider type.
- **`EmbeddingApiConfig`** (Struct) — Configuration for embedding API (OpenAI-compatible).
- **`new`** (Function) — Create EmbeddingApiConfig with defaults for OpenAI.
- **`VcdbStrategy`** (Enum) — vcdb indexing strategy (Single Source of Truth).
- **`EmbeddingSource`** (Enum) — Embedding source for function indexing.
