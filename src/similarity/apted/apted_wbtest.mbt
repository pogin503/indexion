// Whitebox tests for APTED algorithm.

// ============================================================
// TreeNode tests
// ============================================================

///|
test "TreeNode::leaf creates leaf node" {
  let node = TreeNode::leaf("A")
  assert_eq(node.get_label(), "A")
  assert_eq(node.get_children().length(), 0)
  assert_true(node.is_leaf())
}

///|
test "TreeNode::node creates node with children" {
  let child1 = TreeNode::leaf("B")
  let child2 = TreeNode::leaf("C")
  let node = TreeNode::node("A", [child1, child2])
  assert_eq(node.get_label(), "A")
  assert_eq(node.get_children().length(), 2)
  assert_true(not(node.is_leaf()))
}

///|
test "TreeNode::size for single node" {
  let node = TreeNode::leaf("A")
  assert_eq(node.size(), 1)
}

///|
test "TreeNode::size for tree" {
  // A
  // ├── B
  // │   ├── D
  // │   └── E
  // └── C
  let d = TreeNode::leaf("D")
  let e = TreeNode::leaf("E")
  let b = TreeNode::node("B", [d, e])
  let c = TreeNode::leaf("C")
  let a = TreeNode::node("A", [b, c])
  assert_eq(a.size(), 5)
}

///|
test "TreeNode::height for single node" {
  let node = TreeNode::leaf("A")
  assert_eq(node.height(), 1)
}

///|
test "TreeNode::height for tree" {
  let d = TreeNode::leaf("D")
  let e = TreeNode::leaf("E")
  let b = TreeNode::node("B", [d, e])
  let c = TreeNode::leaf("C")
  let a = TreeNode::node("A", [b, c])
  assert_eq(a.height(), 3)
}

// ============================================================
// CostConfig tests
// ============================================================

///|
test "CostConfig::default returns unit costs" {
  let config = CostConfig::default()
  assert_eq(config.get_insert_cost(), 1.0)
  assert_eq(config.get_delete_cost(), 1.0)
  assert_eq(config.get_rename_cost(), 1.0)
}

///|
test "CostConfig::label_cost for same labels" {
  let config = CostConfig::default()
  assert_eq(config.label_cost("A", "A"), 0.0)
}

///|
test "CostConfig::label_cost for different labels" {
  let config = CostConfig::default()
  assert_eq(config.label_cost("A", "B"), 1.0)
}

// ============================================================
// index_tree tests
// ============================================================

///|
test "index_tree for single node" {
  let node = TreeNode::leaf("A")
  let infos = index_tree(node)
  assert_eq(infos.length(), 1)
  assert_eq(infos[0].get_id(), 0)
  assert_eq(infos[0].get_parent(), -1)
  assert_eq(infos[0].get_left_most_leaf(), 0)
}

///|
test "index_tree for small tree" {
  // A
  // ├── B
  // └── C
  let b = TreeNode::leaf("B")
  let c = TreeNode::leaf("C")
  let a = TreeNode::node("A", [b, c])
  let infos = index_tree(a)
  assert_eq(infos.length(), 3)
  // A has id=0, parent=-1
  assert_eq(infos[0].get_id(), 0)
  assert_eq(infos[0].get_parent(), -1)
  // B has id=1, parent=0
  assert_eq(infos[1].get_id(), 1)
  assert_eq(infos[1].get_parent(), 0)
  // C has id=2, parent=0
  assert_eq(infos[2].get_id(), 2)
  assert_eq(infos[2].get_parent(), 0)
}

///|
test "get_keyroots for single node" {
  let node = TreeNode::leaf("A")
  let infos = index_tree(node)
  let keyroots = get_keyroots(infos)
  assert_eq(keyroots.length(), 1)
  assert_eq(keyroots[0], 0)
}

///|
test "get_keyroots for tree with children" {
  // A
  // ├── B
  // └── C
  let b = TreeNode::leaf("B")
  let c = TreeNode::leaf("C")
  let a = TreeNode::node("A", [b, c])
  let infos = index_tree(a)
  let keyroots = get_keyroots(infos)
  // B is leftmost child of A, so not a keyroot
  // A and C are keyroots
  assert_eq(keyroots.length(), 2)
}

// ============================================================
// Tree edit distance tests
// ============================================================

///|
test "compute_tree_edit_distance for identical trees" {
  let tree = TreeNode::leaf("A")
  let dist = compute_tree_edit_distance(tree, tree, CostConfig::default())
  assert_eq(dist, 0.0)
}

///|
test "compute_tree_edit_distance for single insertion" {
  let tree1 = TreeNode::leaf("A")
  let tree2 = TreeNode::node("A", [TreeNode::leaf("B")])
  let dist = compute_tree_edit_distance(tree1, tree2, CostConfig::default())
  assert_eq(dist, 1.0)
}

///|
test "compute_tree_edit_distance for single deletion" {
  let tree1 = TreeNode::node("A", [TreeNode::leaf("B")])
  let tree2 = TreeNode::leaf("A")
  let dist = compute_tree_edit_distance(tree1, tree2, CostConfig::default())
  assert_eq(dist, 1.0)
}

///|
test "compute_tree_edit_distance for single rename" {
  let tree1 = TreeNode::leaf("A")
  let tree2 = TreeNode::leaf("B")
  let dist = compute_tree_edit_distance(tree1, tree2, CostConfig::default())
  assert_eq(dist, 1.0)
}

///|
test "compute_tree_edit_distance for complex trees" {
  // Tree1:
  //   A
  //   └── B
  // Tree2:
  //   A
  //   ├── B
  //   └── C
  let tree1 = TreeNode::node("A", [TreeNode::leaf("B")])
  let tree2 = TreeNode::node("A", [TreeNode::leaf("B"), TreeNode::leaf("C")])
  let dist = compute_tree_edit_distance(tree1, tree2, CostConfig::default())
  // One insertion (C)
  assert_eq(dist, 1.0)
}

///|
test "normalized_tree_edit_distance for identical trees" {
  let tree = TreeNode::node("A", [TreeNode::leaf("B")])
  let dist = normalized_tree_edit_distance(tree, tree, CostConfig::default())
  assert_eq(dist, 0.0)
}

///|
test "normalized_tree_edit_distance returns value in [0,1]" {
  let tree1 = TreeNode::node("A", [TreeNode::leaf("B"), TreeNode::leaf("C")])
  let tree2 = TreeNode::node("X", [TreeNode::leaf("Y"), TreeNode::leaf("Z")])
  let dist = normalized_tree_edit_distance(tree1, tree2, CostConfig::default())
  assert_true(dist >= 0.0)
  assert_true(dist <= 1.0)
}

///|
test "tree_similarity for identical trees" {
  let tree = TreeNode::node("A", [TreeNode::leaf("B")])
  let sim = tree_similarity(tree, tree, CostConfig::default())
  assert_eq(sim, 1.0)
}

// ============================================================
// PEG adapter tests (using TreeNode representation)
// ============================================================

///|
test "peg_cost_config returns default config" {
  let config = peg_cost_config()
  assert_eq(config.get_insert_cost(), 1.0)
  assert_eq(config.get_delete_cost(), 1.0)
}

///|
test "TreeNode with Sym label structure" {
  // Simulate a PEG Sym node
  let tree = TreeNode::leaf("Sym:identifier")
  assert_eq(tree.get_label(), "Sym:identifier")
  assert_true(tree.is_leaf())
}

///|
test "TreeNode with Seq structure" {
  // Simulate a PEG Seq node
  let child1 = TreeNode::leaf("Sym:a")
  let child2 = TreeNode::leaf("Sym:b")
  let tree = TreeNode::node("Seq", [child1, child2])
  assert_eq(tree.get_label(), "Seq")
  assert_eq(tree.get_children().length(), 2)
}

///|
test "TreeNode with nested Star structure" {
  // Simulate a PEG Star node
  let inner = TreeNode::leaf("Sym:x")
  let tree = TreeNode::node("Star", [inner])
  assert_eq(tree.get_label(), "Star")
  assert_eq(tree.get_children().length(), 1)
}

///|
test "tree edit distance for PEG-like structures" {
  // Simulate comparing two PEG expressions:
  // Seq(Sym:a, Sym:b) vs Seq(Sym:a, Sym:c)
  let tree1 = TreeNode::node("Seq", [
    TreeNode::leaf("Sym:a"),
    TreeNode::leaf("Sym:b"),
  ])
  let tree2 = TreeNode::node("Seq", [
    TreeNode::leaf("Sym:a"),
    TreeNode::leaf("Sym:c"),
  ])
  let dist = compute_tree_edit_distance(tree1, tree2, CostConfig::default())
  // One rename: Sym:b -> Sym:c
  assert_eq(dist, 1.0)
}

///|
test "normalized distance for PEG-like structures" {
  let tree1 = TreeNode::node("Star", [TreeNode::leaf("Sym:x")])
  let tree2 = TreeNode::node("Plus", [TreeNode::leaf("Sym:y")])
  let dist = normalized_tree_edit_distance(tree1, tree2, CostConfig::default())
  assert_true(dist >= 0.0)
  assert_true(dist <= 1.0)
}

///|
test "similarity for identical PEG-like structures" {
  let tree = TreeNode::node("Choice", [TreeNode::leaf("Sym:a")])
  let sim = tree_similarity(tree, tree, CostConfig::default())
  assert_eq(sim, 1.0)
}
