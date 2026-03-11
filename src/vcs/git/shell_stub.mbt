///|
pub fn is_repo(_root : String) -> Bool {
  git_is_repo_native(_root)
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
pub fn status_dirty(_root : String, _path : String) -> Bool {
  git_status_dirty_native(_root, query_path(_root, _path))
}

///|
pub fn last_commit_seconds(_root : String, _path : String) -> Int? {
  git_last_commit_seconds_native(_root, query_path(_root, _path))
}
