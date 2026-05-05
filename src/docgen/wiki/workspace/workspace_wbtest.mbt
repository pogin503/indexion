///|
fn temp_wiki_workspace_dir(label : String) -> String {
  let dir = "/tmp/indexion-wiki-workspace/" +
    label +
    "-" +
    @env.now().to_string()
  @config.ensure_dir_recursive(dir)
  dir
}

///|
fn write_test_file(path : String, content : String) -> Unit {
  @config.ensure_parent_dir(path)
  @fs.write_string_to_file(path, content) catch {
    _ => panic()
  }
}

///|
test "resolve wiki dir accepts direct wiki directory" {
  let wiki_dir = temp_wiki_workspace_dir("direct")
  write_test_file(
    wiki_dir + "/wiki.json",
    "{\"title\":\"Docs\",\"pages\":[]}\n",
  )
  assert_eq(resolve_wiki_dir(wiki_dir), Some(wiki_dir))
}

///|
test "wiki content paths come from manifest SoT" {
  let wiki_dir = temp_wiki_workspace_dir("paths")
  write_test_file(
    wiki_dir + "/wiki.json",
    "{\"title\":\"Docs\",\"pages\":[{\"id\":\"home\",\"title\":\"Home\",\"file\":\"home.md\",\"sources\":[],\"children\":[],\"provenance\":null,\"last_actor\":null}]}\n",
  )
  write_test_file(wiki_dir + "/home.md", "# Home\n")
  assert_eq(
    wiki_content_paths(wiki_dir),
    Some([wiki_dir + "/wiki.json", wiki_dir + "/home.md"]),
  )
}

///|
test "wiki search generated path detection" {
  assert_true(is_wiki_search_generated_path(".indexion/wiki/vectors.db"))
  assert_true(
    is_wiki_search_generated_path(".indexion/wiki/search-sections.json"),
  )
  assert_true(
    is_wiki_search_generated_path(".indexion/wiki/tfidf-vocabulary.json"),
  )
  assert_true(is_wiki_search_generated_path(".indexion/wiki/index.md"))
  assert_false(is_wiki_search_generated_path(".indexion/wiki/overview.md"))
}
