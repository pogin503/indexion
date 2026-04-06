// Embedding configuration — shared across digest, search, wiki, and serve.
//
// This module is the Single Source of Truth for embedding provider types,
// constants, and utilities. All consumers import from here instead of
// duplicating these definitions.

///|
/// Default TF-IDF dimension
pub const DEFAULT_TFIDF_DIM : Int = 256

///|
/// OpenAI text-embedding-3-small dimension
pub const OPENAI_EMBEDDING_DIM : Int = 1536

///|
/// Default TF-IDF provider key
pub const DEFAULT_TFIDF_KEY : String = "tfidf"

///|
/// Default embedding API key environment variable name.
pub const DEFAULT_API_KEY_ENV : String = "OPENAI_API_KEY"

///|
/// Default embedding API base URL.
pub const DEFAULT_API_BASE_URL : String = "https://api.openai.com/v1/embeddings"

///|
/// Default embedding model name.
pub const DEFAULT_EMBEDDING_MODEL : String = "text-embedding-3-small"

///|
/// Configuration for embedding API (OpenAI-compatible).
pub(all) struct EmbeddingApiConfig {
  /// API key.
  api_key : String
  /// Environment variable name the API key was resolved from.
  api_key_env : String
  /// API base URL for embeddings endpoint.
  base_url : String
  /// Embedding model name.
  model : String
  /// Embedding vector dimension.
  dim : Int
} derive(Eq, Show)

///|
/// Create EmbeddingApiConfig with defaults for OpenAI.
pub fn EmbeddingApiConfig::new(api_key : String) -> EmbeddingApiConfig {
  {
    api_key,
    api_key_env: DEFAULT_API_KEY_ENV,
    base_url: DEFAULT_API_BASE_URL,
    model: DEFAULT_EMBEDDING_MODEL,
    dim: OPENAI_EMBEDDING_DIM,
  }
}

///|
/// Embedding provider type.
/// Used for CLI parsing and display. The actual config uses providers array.
pub(all) enum EmbeddingProvider {
  /// Local TF-IDF (no external dependencies).
  TfIdf(Int) // dimension
  /// OpenAI-compatible embedding API.
  OpenAI(EmbeddingApiConfig)
  /// Pre-computed embeddings from file.
  Precomputed(String) // file_path
} derive(Eq, Show)

///|
/// vcdb indexing strategy (Single Source of Truth).
pub(all) enum VcdbStrategy {
  /// Brute force (exact, slow for large datasets).
  BruteForce
  /// HNSW (approximate, fast).
  Hnsw
  /// IVF (approximate, good for very large datasets).
  Ivf
} derive(Eq, Show)

///|
/// Embedding source for function indexing.
pub(all) enum EmbeddingSource {
  /// Use raw function info (name + kind + namespace).
  Raw
  /// Use LLM-generated impressions (requires impression generation).
  Impression
  /// Use raw with callees context appended.
  RawWithContext
} derive(Eq, Show)

///|
/// Per-provider configuration.
/// Each provider is identified by a unique key and has a kind ("tfidf" or "remote").
pub(all) struct ProviderConfig {
  /// Stable identifier used for file naming and manifest tracking.
  key : String
  /// Provider kind: "tfidf" for local TF-IDF, "remote" for API-based embedding.
  kind : String
  /// Embedding vector dimension.
  dim : Int
  /// API configuration (required for kind="remote", None for kind="tfidf").
  api_config : EmbeddingApiConfig?
} derive(Eq, Show)

///|
/// Create a default TF-IDF provider config.
pub fn ProviderConfig::tfidf(
  dim? : Int = DEFAULT_TFIDF_DIM,
) -> ProviderConfig {
  { key: DEFAULT_TFIDF_KEY, kind: "tfidf", dim, api_config: None }
}

///|
/// Create a remote provider config from an EmbeddingApiConfig.
/// Key defaults to the sanitized model name.
pub fn ProviderConfig::remote(api_config : EmbeddingApiConfig) -> ProviderConfig {
  {
    key: sanitize_provider_key(api_config.model),
    kind: "remote",
    dim: api_config.dim,
    api_config: Some(api_config),
  }
}

///|
/// Sanitize a string for use as a provider key (filesystem-safe).
/// Replaces non-alphanumeric chars (except hyphen, underscore, dot) with hyphen.
pub fn sanitize_provider_key(raw : String) -> String {
  let buf = StringBuilder::new()
  for ch in raw {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' ||
      ch == '.' {
      buf.write_char(ch)
    } else {
      buf.write_char('-')
    }
  }
  buf.to_string()
}
