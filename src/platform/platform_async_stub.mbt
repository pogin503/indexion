///|
/// Stub implementations of platform-dependent async operations for non-native targets.

///|
pub async fn make_executable(_path : String) -> Unit {
  fail("make_executable is only supported on native target")
}

///|
pub async fn install_binary(_src : String, _dst : String) -> Unit {
  fail("install_binary is only supported on native target")
}

///|
pub async fn extract_archive(_archive : String, _dest : String) -> Unit {
  fail("extract_archive is only supported on native target")
}
