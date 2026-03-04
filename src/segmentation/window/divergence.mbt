// Window divergence calculation functions.
// Uses shared utilities from segmentation/utils for common operations.

///|
/// Calculate TF-IDF divergence between adjacent sentence windows.
/// Returns divergence values and their corresponding positions.
pub fn calculate_window_tfidf_divergence(
  sentences : Array[@sentence.Sentence],
  window_size : Int,
) -> @types.WindowDivergence {
  let divergence_values : Array[Double] = []
  let window_end_positions : Array[Int] = []

  // Need at least window_size + 1 sentences to compare two windows
  if sentences.length() < window_size + 1 {
    return @types.WindowDivergence::new(divergence_values, window_end_positions)
  }

  // Build windows
  let windows : Array[String] = []
  let window_ends : Array[Int] = []

  let num_windows = sentences.length() - window_size + 1
  for i = 0; i < num_windows; i = i + 1 {
    windows.push(@utils.combine_sentences(sentences, i, window_size))
    window_ends.push(@utils.get_window_end(sentences, i, window_size))
  }

  // Calculate TF-IDF distances between adjacent windows using utils
  let tfidf_values = @utils.calculate_adjacent_tfidf_distance(windows)

  // Normalize TF-IDF values using utils
  let normalized_tfidf = @utils.min_max_normalize(tfidf_values)

  // Build result (using tfidf_weight = 1.0 since we don't have NCD)
  let length = if normalized_tfidf.length() < window_ends.length() - 1 {
    normalized_tfidf.length()
  } else {
    window_ends.length() - 1
  }

  for i = 0; i < length; i = i + 1 {
    divergence_values.push(normalized_tfidf[i])
    window_end_positions.push(window_ends[i])
  }

  @types.WindowDivergence::new(divergence_values, window_end_positions)
}

///|
/// Normalize an array of values using Min-Max normalization.
/// Returns values in range [0, 1].
/// If all values are the same, returns 0.5 for all.
///
/// Note: This is a convenience re-export from segmentation/utils.
pub fn min_max_normalize(values : Array[Double]) -> Array[Double] {
  @utils.min_max_normalize(values)
}

///|
/// Find local maxima indices where values exceed the threshold.
/// A local maximum is a value that is greater than both its neighbors.
///
/// Note: This is a convenience re-export from segmentation/utils.
pub fn find_local_maxima(
  values : Array[Double],
  threshold : Double,
) -> Array[Int] {
  @utils.find_local_maxima(values, threshold)
}
