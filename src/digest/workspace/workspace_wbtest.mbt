///|
test "generated path detection ignores indexion artifacts" {
  assert_true(is_indexion_generated_path(".indexion"))
  assert_true(is_indexion_generated_path(".indexion/digest/manifest.json"))
  assert_true(is_indexion_generated_path("pkg/.indexion/wiki/vectors.db"))
  assert_false(is_indexion_generated_path("src/.indexion_note.mbt"))
  assert_false(is_indexion_generated_path("src/indexion.mbt"))
}

///|
test "relevant changed paths skip generated artifacts" {
  assert_false(has_relevant_changed_path([]))
  assert_false(has_relevant_changed_path([".indexion/digest/manifest.json"]))
  assert_true(
    has_relevant_changed_path([".indexion/digest/manifest.json", "src/main.mbt"]),
  )
}

///|
fn temp_workspace_dir(label : String) -> String {
  let dir = "/tmp/indexion-digest-workspace/" +
    label +
    "-" +
    @env.now().to_string()
  @config.ensure_dir_recursive(dir)
  dir
}

///|
test "resolve workspace dir uses project root for nested paths" {
  let root = temp_workspace_dir("root")
  @config.ensure_dir_recursive(root + "/src/pkg")
  @config.ensure_dir_recursive(root + "/.indexion")
  assert_eq(resolve_workspace_dir(root + "/src/pkg"), root)
}

///|
test "resolve source dir follows project digest index owner" {
  let root = temp_workspace_dir("source-owner")
  let nested = root + "/src/pkg"
  @config.ensure_dir_recursive(nested)
  @config.ensure_dir_recursive(root + "/.indexion")
  let project_index = resolve_index_dir(nested).unwrap()
  assert_eq(resolve_source_dir_for_index(nested, project_index), root)
  assert_eq(
    resolve_source_dir_for_index(nested, nested + "/.indexion/digest"),
    nested,
  )
}
