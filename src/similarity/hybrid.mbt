// Hybrid NCD + TF-IDF similarity strategy.
// Combines compression-based and lexical divergence metrics.

///|
/// Hybrid similarity strategy combining NCD and TF-IDF.
/// Uses weighted average of both metrics for robust similarity measurement.
pub struct HybridStrategy {
  config : HybridConfig
} derive(Eq, Show)

///|
/// Create a new HybridStrategy with default config (50/50 weights).
pub fn HybridStrategy::new() -> HybridStrategy {
  { config: HybridConfig::new() }
}

///|
/// Create a HybridStrategy with custom config.
pub fn HybridStrategy::with_config(config : HybridConfig) -> HybridStrategy {
  { config, }
}

///|
/// Get the configuration.
pub fn HybridStrategy::get_config(self : HybridStrategy) -> HybridConfig {
  self.config
}

///|
pub impl SimilarityStrategy for HybridStrategy with name(self) {
  ignore(self)
  "hybrid"
}

///|
pub impl SimilarityStrategy for HybridStrategy with distance(self, a, b) {
  // Calculate both metrics
  let ncd_val = @utils.ncd(a, b)
  let tfidf_val = calculate_tfidf_distance_internal(a, b)
  // Apply weighted average
  self.config.ncd_weight * ncd_val + self.config.tfidf_weight * tfidf_val
}

///|
pub impl SimilarityStrategy for HybridStrategy with similarity(self, a, b) {
  1.0 - self.distance(a, b)
}

///|
/// Internal helper to calculate TF-IDF distance.
fn calculate_tfidf_distance_internal(a : String, b : String) -> Double {
  if a.length() == 0 && b.length() == 0 {
    return 0.0
  }
  if a.length() == 0 || b.length() == 0 {
    return 1.0
  }
  let tokens_a = @tokenizer.tokenize_for_tfidf(a)
  let tokens_b = @tokenizer.tokenize_for_tfidf(b)
  let docs = [tokens_a, tokens_b]
  let df = @tfidf.build_document_frequency(docs)
  let vec_a = @tfidf.build_tfidf_vector(tokens_a, df, 2)
  let vec_b = @tfidf.build_tfidf_vector(tokens_b, df, 2)
  @tfidf.cosine_distance(vec_a, vec_b)
}

///|
/// Calculate hybrid distances for adjacent texts in an array.
/// Returns array where result[i] = hybrid_distance(texts[i], texts[i+1]).
pub fn calculate_adjacent_hybrid(
  texts : Array[String],
  config : HybridConfig,
) -> Array[Double] {
  if texts.length() < 2 {
    return []
  }
  // Calculate both metrics for all adjacent pairs
  let ncd_values = @utils.calculate_adjacent_ncd(texts)
  let tfidf_values = @tfidf.calculate_adjacent_tfidf_distance(texts)
  // Normalize each array to [0, 1] using min-max normalization
  let ncd_normalized = @utils.min_max_normalize(ncd_values)
  let tfidf_normalized = @utils.min_max_normalize(tfidf_values)
  // Combine with weights
  let length = if ncd_normalized.length() < tfidf_normalized.length() {
    ncd_normalized.length()
  } else {
    tfidf_normalized.length()
  }
  let results : Array[Double] = []
  for i = 0; i < length; i = i + 1 {
    let hybrid = config.ncd_weight * ncd_normalized[i] +
      config.tfidf_weight * tfidf_normalized[i]
    results.push(hybrid)
  }
  results
}
