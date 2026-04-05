///|
test "MinHashSignature::from_tokens creates signature of correct length" {
  let tokens = ["hello", "world", "foo", "bar"]
  let sig = MinHashSignature::from_tokens(tokens)
  assert_eq!(sig.get_values().length(), 128)
}

///|
test "MinHashSignature::jaccard returns 1.0 for identical token sets" {
  let tokens = ["the", "quick", "brown", "fox"]
  let sig1 = MinHashSignature::from_tokens(tokens)
  let sig2 = MinHashSignature::from_tokens(tokens)
  assert_eq!(sig1.jaccard(sig2), 1.0)
}

///|
test "MinHashSignature::jaccard returns high value for similar sets" {
  let tokens1 = ["the", "quick", "brown", "fox", "jumps"]
  let tokens2 = ["the", "quick", "brown", "fox", "runs"]
  let sig1 = MinHashSignature::from_tokens(tokens1)
  let sig2 = MinHashSignature::from_tokens(tokens2)
  let jaccard = sig1.jaccard(sig2)
  // True Jaccard = |intersection|/|union| = 4/6 ≈ 0.667
  // MinHash estimate should be in the ballpark (±0.2)
  assert_true!(jaccard > 0.4)
  assert_true!(jaccard < 0.9)
}

///|
test "MinHashSignature::jaccard returns low value for disjoint sets" {
  let tokens1 = ["alpha", "beta", "gamma"]
  let tokens2 = ["delta", "epsilon", "zeta"]
  let sig1 = MinHashSignature::from_tokens(tokens1)
  let sig2 = MinHashSignature::from_tokens(tokens2)
  let jaccard = sig1.jaccard(sig2)
  // True Jaccard = 0/6 = 0.0
  assert_true!(jaccard < 0.2)
}

///|
test "MinHashSignature::from_tokens deduplicates tokens" {
  let tokens1 = ["a", "b", "c"]
  let tokens2 = ["a", "a", "b", "b", "c", "c"]
  let sig1 = MinHashSignature::from_tokens(tokens1)
  let sig2 = MinHashSignature::from_tokens(tokens2)
  // Same unique set → same signature
  assert_eq!(sig1.jaccard(sig2), 1.0)
}

///|
test "MinHashSignature::from_tokens handles empty input" {
  let tokens : Array[String] = []
  let sig = MinHashSignature::from_tokens(tokens)
  assert_eq!(sig.get_values().length(), 128)
  // All values should be max int (no minimums found)
  for v in sig.get_values() {
    assert_eq!(v, 2147483647)
  }
}

///|
test "LSHIndex finds candidate pairs for highly similar documents" {
  let index = LSHIndex::new(0.3)
  // Two very similar token sets (high overlap)
  let tokens1 = [
    "fn", "main", "let", "x", "=", "println", "return", "if", "else", "for",
  ]
  let tokens2 = [
    "fn", "main", "let", "y", "=", "println", "return", "if", "else", "for",
  ]
  // One completely different
  let tokens3 = [
    "import", "os", "sys", "path", "join", "open", "read", "write", "close",
    "flush",
  ]
  let sig1 = MinHashSignature::from_tokens(tokens1)
  let sig2 = MinHashSignature::from_tokens(tokens2)
  let sig3 = MinHashSignature::from_tokens(tokens3)
  ignore(index.insert(sig1))
  ignore(index.insert(sig2))
  ignore(index.insert(sig3))
  // True Jaccard(1,2) = 9/12 = 0.75, should reliably be found
  let pairs = index.candidate_pairs()
  let mut has_01 = false
  for pair in pairs {
    let (i, j) = pair
    if i == 0 && j == 1 {
      has_01 = true
    }
  }
  assert_true!(has_01)
}

///|
test "LSHIndex::candidate_pairs_above_threshold filters by jaccard" {
  let index = LSHIndex::new(0.3)
  let tokens1 = ["a", "b", "c", "d", "e", "f", "g", "h"]
  let tokens2 = ["a", "b", "c", "d", "e", "f", "g", "i"]
  let tokens3 = ["x", "y", "z", "w", "v", "u", "t", "s"]
  let sig1 = MinHashSignature::from_tokens(tokens1)
  let sig2 = MinHashSignature::from_tokens(tokens2)
  let sig3 = MinHashSignature::from_tokens(tokens3)
  ignore(index.insert(sig1))
  ignore(index.insert(sig2))
  ignore(index.insert(sig3))
  let results = index.candidate_pairs_above_threshold(0.5)
  // (0,1) should pass threshold, (0,2) and (1,2) should not
  for result in results {
    let (i, j, jaccard) = result
    assert_true!(jaccard >= 0.5)
    // Should not be a pair of completely different documents
    assert_true!(!(i == 0 && j == 2) && !(i == 1 && j == 2))
  }
}

///|
test "select_band_params returns valid factorization" {
  let (bands, rows) = select_band_params(0.8)
  assert_true!(bands * rows <= 128)
  assert_true!(bands >= 1)
  assert_true!(rows >= 1)
}

///|
test "select_band_params adapts to threshold" {
  // Higher threshold → fewer bands, more rows per band (stricter matching)
  let (bands_high, rows_high) = select_band_params(0.9)
  let (bands_low, rows_low) = select_band_params(0.3)
  // Higher threshold should use more rows per band (stricter)
  // or fewer bands (less chance of accidental match)
  assert_true!(rows_high >= rows_low || bands_high <= bands_low)
}
