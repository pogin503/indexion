///|
#warnings("-unused_async")
async fn git_is_repo_native(_root : String) -> Bool {
  false
}

///|
#warnings("-unused_async")
async fn git_status_dirty_native(_root : String, _path : String) -> Bool {
  false
}

///|
#warnings("-unused_async")
async fn git_last_commit_seconds_native(_root : String, _path : String) -> Int? {
  None
}

///|
#warnings("-unused_async")
async fn git_repo_root_native(_anchor : String) -> String? {
  None
}

///|
#warnings("-unused_async")
async fn git_head_commit_native(
  _root : String,
  short? : Bool = false,
) -> String? {
  ignore(short)
  None
}

///|
#warnings("-unused_async")
async fn git_head_commit_seconds_native(_root : String) -> Int? {
  None
}

///|
#warnings("-unused_async")
async fn git_changed_files_native(
  _root : String,
  _base : String,
  _paths : Array[String],
) -> Array[String]? {
  None
}

///|
#warnings("-unused_async")
async fn git_worktree_changed_files_native(
  _root : String,
  _paths : Array[String],
) -> Array[String]? {
  None
}

///|
/// Return the file modification time in seconds, or None if unavailable.
#warnings("-unused_async")
pub async fn file_mtime_seconds(_path : String) -> Int? {
  None
}
