///|
/// # Search Types
///
/// Domain-agnostic types for the shared search engine.
/// Used by both `grep --semantic=similar:` and the `search` CLI command.

///|
/// A document in the search corpus. Domain-agnostic — any module that needs
/// vector similarity search converts its data into SearchDocuments.
pub(all) struct SearchDocument {
  /// Unique ID within corpus (e.g. "file:line" or "page#anchor")
  id : String
  /// The text to embed for similarity matching
  text : String
  /// Display name (function name, section heading, etc.)
  title : String
  /// Source file path
  source : String
  /// Line number (0 for document-level entries)
  line : Int
  /// Entry kind (e.g. "fn", "section", "page")
  kind : String
  /// Structured attributes forwarded to vcdb for filtering.
  /// Keys: node_type, node_kind, language, module, parent, etc.
  /// Values are strings; the engine converts to AttrValue internally.
  attrs : Map[String, String]
} derive(ToJson)

///|
/// A search result hit with similarity score.
pub(all) struct SearchHit {
  document : SearchDocument
  score : Double
} derive(ToJson)
