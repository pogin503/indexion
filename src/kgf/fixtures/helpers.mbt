///|
/// Common helpers for fixture tests.
/// Uses @config_paths SoT for path operations and ancestor traversal.

///|
/// Find a named directory by walking up from "." using find_project_root.
/// Returns the full relative path to the directory, or None if not found.
fn find_ancestor_dir(name : String) -> String? {
  match @config_paths.find_project_root(".", [name]) {
    Some(root) => {
      let joined = @config_paths.join_path(root, name)
      Some(@config_paths.normalize_path(joined))
    }
    None => None
  }
}

///|
/// Find the fixtures directory by walking up from cwd.
pub fn find_fixtures_dir() -> String? {
  find_ancestor_dir("fixtures")
}

///|
/// Find the kgfs directory by walking up from cwd.
pub fn find_kgfs_dir() -> String? {
  find_ancestor_dir("kgfs")
}

///|
/// Find the fixtures directory, falling back to "fixtures" if not found.
pub fn get_fixtures_dir() -> String {
  find_fixtures_dir().unwrap_or("fixtures")
}

///|
/// Find the kgfs directory, falling back to "kgfs" if not found.
pub fn get_kgfs_dir() -> String {
  find_kgfs_dir().unwrap_or("kgfs")
}
