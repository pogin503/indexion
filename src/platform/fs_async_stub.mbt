///|
/// Stub implementations of async file operations for non-native targets.

///|
#warnings("-unused_async")
pub async fn copy_file(_src : String, _dst : String) -> Unit {
  fail("copy_file is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn copy_dir_recursive(_src : String, _dst : String) -> Unit {
  fail("copy_dir_recursive is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn create_temp_dir(_prefix : String) -> String {
  fail("create_temp_dir is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn remove_dir_recursive(_path : String) -> Unit {
  fail("remove_dir_recursive is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn path_exists_async(_path : String) -> Bool {
  fail("path_exists_async is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn write_bytes_async(_path : String, _data : Bytes) -> Unit {
  fail("write_bytes_async is only supported on native target")
}

///|
#warnings("-unused_async")
pub async fn ensure_dir_async(_path : String) -> Unit {
  fail("ensure_dir_async is only supported on native target")
}
