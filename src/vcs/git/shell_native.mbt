///|
pub fn is_repo(root : String) -> Bool {
  git_is_repo_native(root)
}

///|
pub fn query_path(root : String, path : String) -> String {
  let rel = @config_paths.relative_to(root, path)
  if rel.length() == 0 {
    "."
  } else {
    rel
  }
}

///|
pub fn status_dirty(root : String, path : String) -> Bool {
  git_status_dirty_native(root, query_path(root, path))
}

///|
pub fn last_commit_seconds(root : String, path : String) -> Int? {
  git_last_commit_seconds_native(root, query_path(root, path))
}
