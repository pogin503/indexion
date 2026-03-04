// TF-IDF cosine similarity strategy.
// Wraps the existing TF-IDF implementation from text/tfidf.

///|
/// TF-IDF based similarity strategy.
/// Uses term frequency-inverse document frequency with cosine similarity.
pub struct TfidfStrategy {
  /// Placeholder field for future configuration.
  priv _unused : Unit
} derive(Eq, Show)

///|
/// Create a new TfidfStrategy.
pub fn TfidfStrategy::new() -> TfidfStrategy {
  { _unused: () }
}

///|
pub impl SimilarityStrategy for TfidfStrategy with name(self) {
  ignore(self)
  "tfidf"
}

///|
pub impl SimilarityStrategy for TfidfStrategy with distance(self, a, b) {
  ignore(self)
  calculate_tfidf_distance(a, b)
}

///|
pub impl SimilarityStrategy for TfidfStrategy with similarity(self, a, b) {
  1.0 - self.distance(a, b)
}

///|
/// Calculate TF-IDF cosine distance between two texts.
fn calculate_tfidf_distance(a : String, b : String) -> Double {
  // Handle empty strings
  if a.length() == 0 && b.length() == 0 {
    return 0.0
  }
  if a.length() == 0 || b.length() == 0 {
    return 1.0
  }
  // Tokenize both texts
  let tokens_a = @tokenizer.tokenize_for_tfidf(a)
  let tokens_b = @tokenizer.tokenize_for_tfidf(b)
  // Build document frequency from both documents
  let docs = [tokens_a, tokens_b]
  let df = @tfidf.build_document_frequency(docs)
  // Build TF-IDF vectors
  let vec_a = @tfidf.build_tfidf_vector(tokens_a, df, 2)
  let vec_b = @tfidf.build_tfidf_vector(tokens_b, df, 2)
  // Return cosine distance
  @tfidf.cosine_distance(vec_a, vec_b)
}

///|
/// Calculate TF-IDF distances for adjacent texts in an array.
/// Returns array where result[i] = distance(texts[i], texts[i+1]).
pub fn calculate_adjacent_tfidf(texts : Array[String]) -> Array[Double] {
  @tfidf.calculate_adjacent_tfidf_distance(texts)
}

///|
/// Batch TF-IDF similarity calculator.
/// Precomputes TF-IDF vectors for efficient pairwise comparison.
pub struct TfidfBatch(@tfidf.TfidfBatch)

///|
/// Create a batch calculator from texts.
/// Each text is tokenized once and TF-IDF vectors are precomputed.
pub fn TfidfBatch::from_texts(texts : Array[String]) -> TfidfBatch {
  TfidfBatch(@tfidf.TfidfBatch::from_texts(texts))
}

///|
/// Get the number of documents in the batch.
pub fn TfidfBatch::length(self : TfidfBatch) -> Int {
  self.0.length()
}

///|
/// Calculate similarity between two documents by index.
pub fn TfidfBatch::similarity(self : TfidfBatch, i : Int, j : Int) -> Double {
  self.0.similarity(i, j)
}

///|
/// Calculate all pairwise similarities above a threshold.
/// Returns array of (i, j, similarity) where i < j.
pub fn TfidfBatch::all_pairs_above_threshold(
  self : TfidfBatch,
  threshold : Double,
) -> Array[(Int, Int, Double)] {
  self.0.all_pairs_above_threshold(threshold)
}
