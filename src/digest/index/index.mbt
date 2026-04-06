// DigestIndex - Main orchestration for reminiscent backtracking.
// Integrates vcdb for vector storage with function extraction and embedding.

///|
/// Result of building/updating the index.
pub struct BuildResult {
  /// Number of functions indexed.
  mut indexed_count : Int
  /// Number of functions skipped (already up-to-date).
  mut skipped_count : Int
  /// Number of functions removed.
  mut removed_count : Int
  /// Errors encountered.
  errors : Array[String]
} derive(Eq, Show)

///|
/// Create an empty BuildResult.
pub fn BuildResult::new() -> BuildResult {
  { indexed_count: 0, skipped_count: 0, removed_count: 0, errors: [] }
}

// TfidfEmbeddingProvider: use @text_embed.TfidfEmbeddingProvider (SoT)
// Type alias for backward compatibility within digest package.

///|
pub type TfidfEmbeddingProvider = @text_embed.TfidfEmbeddingProvider

///|
/// DigestIndex - Main index structure.
/// Uses SearchEngine as the vcdb backend for consistency with search command.
pub struct DigestIndex {
  /// Manifest for tracking state.
  mut manifest : @manifest.DigestManifest
  /// Search engine wrapping vcdb.
  engine : @search.SearchEngine
  /// TF-IDF embedding provider.
  provider : TfidfEmbeddingProvider
  /// Cached function units.
  units : Map[String, @types.FunctionUnit]
  /// Reverse index: vector_id -> function_id for O(1) query lookups.
  vid_to_fid : Map[Int64, String]
}

///|
/// Query by purpose text with optional FilterExpr.
pub fn DigestIndex::query(
  self : DigestIndex,
  purpose : String,
  top_k : Int,
  filter? : @vcdb_filter.FilterExpr? = None,
) -> Array[@types.QueryHit] {
  let vector = self.provider.embed(purpose)
  let hits = self.engine.search_vector(vector, top_k, filter~)
  let results : Array[@types.QueryHit] = []
  for hit in hits {
    let vid = hit.id.to_int64()
    match self.vid_to_fid.get(vid) {
      Some(fid) =>
        match self.units.get(fid) {
          Some(unit) =>
            results.push(@types.QueryHit::new(unit, hit.score, []))
          None => ()
        }
      None => ()
    }
  }
  results
}

///|
/// Restore function units from a CodeGraph without re-embedding.
/// Used by query path to populate the units cache from a persisted graph.
pub fn DigestIndex::restore_units_from_graph(
  self : DigestIndex,
  graph : @graph.CodeGraph,
  extract_config : @extract.ExtractConfig,
) -> Unit {
  let units = @extract.extract_function_units(graph, extract_config)
  for unit in units {
    self.units.set(unit.id(), unit)
  }
}

///|
/// Serialize index for persistence.
pub fn DigestIndex::serialize(self : DigestIndex) -> (String, Bytes) {
  let manifest_json = self.manifest.to_json_string()
  let db_bytes = self.engine.serialize()
  (manifest_json, db_bytes)
}

///|
/// Get statistics about the index.
pub fn DigestIndex::stats(self : DigestIndex) -> Map[String, Int] {
  let stats : Map[String, Int] = {}
  stats.set("function_count", self.manifest.functions.length())
  stats.set("vector_count", self.engine.size())
  stats.set("embedding_dim", self.provider.dim)
  stats
}
