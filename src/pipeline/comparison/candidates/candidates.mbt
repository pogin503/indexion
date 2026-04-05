///|
/// Candidate pair generation for batch comparison.
/// Provides brute-force enumeration and TF-IDF inverted-index pre-filtering.

///|
/// Generate all (i, j) pairs where i < j.
pub fn brute_force(n : Int) -> Array[(Int, Int)] {
  let pairs : Array[(Int, Int)] = []
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      pairs.push((i, j))
    }
  }
  pairs
}

///|
/// Use TF-IDF inverted index to find candidate pairs sharing tokens.
/// Takes (display_name, content) pairs. Returns (i, j) where i < j.
pub fn tfidf_prefilter(
  files : Array[(String, String)],
  registry : @kgf_registry.KGFRegistry?,
  prefilter_threshold : Double,
) -> Array[(Int, Int)] {
  let (tokenized, _) = @kgf_features.tokenize_files_with_kgf(files, registry)
  let batch = @tfidf.TfidfBatch::from_tokens(tokenized)
  let results = batch.all_pairs_above_threshold(prefilter_threshold)
  let pairs : Array[(Int, Int)] = []
  for result in results {
    let (i, j, _) = result
    let lo = if i < j { i } else { j }
    let hi = if i < j { j } else { i }
    pairs.push((lo, hi))
  }
  pairs
}

///|
/// Normalize raw TF-IDF results to (i, j) pairs where i < j.
pub fn normalize_pairs(raw : Array[(Int, Int, Double)]) -> Array[(Int, Int)] {
  let pairs : Array[(Int, Int)] = []
  for r in raw {
    let (i, j, _) = r
    let lo = if i < j { i } else { j }
    let hi = if i < j { j } else { i }
    pairs.push((lo, hi))
  }
  pairs
}

///|
/// Use MinHash + LSH to find candidate pairs with approximate Jaccard similarity.
/// Near-linear time complexity: O(N × num_hashes × bands) for indexing,
/// versus O(N²) for brute-force or inverted-index approaches.
/// Takes (display_name, content) pairs. Returns (i, j) where i < j.
pub fn minhash_prefilter(
  files : Array[(String, String)],
  registry : @kgf_registry.KGFRegistry?,
  prefilter_threshold : Double,
) -> Array[(Int, Int)] {
  let (tokenized, _) = @kgf_features.tokenize_files_with_kgf(files, registry)
  let index = @minhash.LSHIndex::new(prefilter_threshold)
  for tokens in tokenized {
    let sig = @minhash.MinHashSignature::from_tokens(tokens)
    ignore(index.insert(sig))
  }
  let results = index.candidate_pairs_above_threshold(prefilter_threshold)
  let pairs : Array[(Int, Int)] = []
  for result in results {
    let (i, j, _) = result
    pairs.push((i, j))
  }
  pairs
}

///|
/// Create a deduplication key for a pair (i, j).
pub fn pair_key(i : Int, j : Int) -> String {
  i.to_string() + ":" + j.to_string()
}
