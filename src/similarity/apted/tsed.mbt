// TSED (Tree Structure Edit Distance) - Tree similarity using
// normalized edit distance with max-based normalization.
// No magic number penalties.

///|
/// Prepare a tree for TSED: apply label finalization and index it.
/// Returns the indexed tree and its size for reuse.
pub fn prepare_tsed_tree(
  tree : TreeNode,
  config : TSEDConfig,
) -> (IndexedTree, Int) {
  let prepared = if config.finalize_labels {
    tree.with_finalized_labels()
  } else {
    tree
  }
  index_tree_with_size(prepared)
}

///|
/// Calculate TSED similarity on pre-indexed trees.
/// Returns a value in [0, 1] where 1 = identical trees.
pub fn calculate_tsed_indexed(
  t1 : IndexedTree,
  size1 : Int,
  t2 : IndexedTree,
  size2 : Int,
  config : TSEDConfig,
) -> Double {
  let max_size = if size1 > size2 {
    size1.to_double()
  } else {
    size2.to_double()
  }
  if max_size <= 0.0 {
    return 1.0
  }
  let distance = compute_tree_edit_distance_indexed(
    t1, size1, t2, size2, config.cost_config,
  )
  let similarity = 1.0 - distance / max_size
  if similarity < 0.0 {
    0.0
  } else if similarity > 1.0 {
    1.0
  } else {
    similarity
  }
}

///|
/// Exact upper bound on TSED similarity based on sizes alone.
///
/// With max-based normalization:
///   best case dist = max_size - min_size
///   upper_bound = 1 - (max_size - min_size) / max_size = min_size / max_size
pub fn tsed_similarity_upper_bound(size1 : Int, size2 : Int) -> Double {
  if size1 == 0 && size2 == 0 {
    return 1.0
  }
  if size1 <= 0 || size2 <= 0 {
    return 0.0
  }
  let min_size = if size1 < size2 { size1 } else { size2 }
  let max_size = if size1 > size2 { size1 } else { size2 }
  min_size.to_double() / max_size.to_double()
}

///|
/// Calculate TSED similarity between two trees.
/// Returns a value in [0, 1] where 1 = identical trees.
///
/// Normalization: max(1 - dist / max(size1, size2), 0)
///
/// This normalization ensures:
/// - Identical trees → 1.0 (regardless of size)
/// - All labels different, same structure → 0.0
/// - No magic number penalties
pub fn calculate_tsed(
  tree1 : TreeNode,
  tree2 : TreeNode,
  config : TSEDConfig,
) -> Double {
  let (t1, size1) = prepare_tsed_tree(tree1, config)
  let (t2, size2) = prepare_tsed_tree(tree2, config)
  calculate_tsed_indexed(t1, size1, t2, size2, config)
}

///|
/// Calculate TSED distance between two trees.
/// Returns 1 - similarity, a value in [0, 1] where 0 = identical trees.
pub fn calculate_tsed_distance(
  tree1 : TreeNode,
  tree2 : TreeNode,
  config : TSEDConfig,
) -> Double {
  1.0 - calculate_tsed(tree1, tree2, config)
}

///|
/// Early pruning: determine if two trees are worth comparing.
/// Uses size ratio to estimate an upper bound on similarity.
/// Returns true if comparison should proceed.
pub fn should_compare_trees(
  tree1 : TreeNode,
  tree2 : TreeNode,
  threshold : Double,
) -> Bool {
  tsed_similarity_upper_bound(tree1.size(), tree2.size()) >= threshold
}
