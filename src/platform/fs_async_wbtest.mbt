///|
async test "create_temp_dir: creates directory that exists" {
  let tmp = create_temp_dir("indexion-test")
  let exists = path_exists_async(tmp)
  assert_true(exists)
  remove_dir_recursive(tmp)
}

///|
async test "write_bytes_async + path_exists_async: write file and verify" {
  let tmp = create_temp_dir("indexion-test")
  let file_path = path_join(tmp, "test.txt")
  let data = b"hello world"
  write_bytes_async(file_path, data)
  let exists = path_exists_async(file_path)
  assert_true(exists)
  remove_dir_recursive(tmp)
}

///|
async test "copy_file: copies file correctly" {
  let tmp = create_temp_dir("indexion-test")
  let src = path_join(tmp, "src.txt")
  let dst = path_join(tmp, "dst.txt")
  let data = b"copy test data"
  write_bytes_async(src, data)
  copy_file(src, dst)
  let exists = path_exists_async(dst)
  assert_true(exists)
  let content = @async_fs.read_file(dst)
  let content_bytes = content.binary()
  assert_eq(content_bytes.length(), data.length())
  remove_dir_recursive(tmp)
}

///|
async test "copy_dir_recursive: copies nested directory structure" {
  let tmp = create_temp_dir("indexion-test")
  let src_dir = path_join(tmp, "src")
  let dst_dir = path_join(tmp, "dst")
  ensure_dir_async(src_dir)
  let sub_dir = path_join(src_dir, "sub")
  ensure_dir_async(sub_dir)
  write_bytes_async(path_join(src_dir, "a.txt"), b"file a")
  write_bytes_async(path_join(sub_dir, "b.txt"), b"file b")
  copy_dir_recursive(src_dir, dst_dir)
  assert_true(path_exists_async(path_join(dst_dir, "a.txt")))
  assert_true(path_exists_async(path_join(dst_dir, "sub")))
  assert_true(path_exists_async(path_join(dst_dir, "sub/b.txt")))
  remove_dir_recursive(tmp)
}

///|
async test "make_executable: does not error on regular file" {
  let tmp = create_temp_dir("indexion-test")
  let file_path = path_join(tmp, "run.sh")
  write_bytes_async(file_path, b"#!/bin/sh\necho hello")
  make_executable(file_path)
  let can_exec = @async_fs.can_execute(file_path)
  match detect_platform() {
    Windows => ()
    _ => assert_true(can_exec)
  }
  remove_dir_recursive(tmp)
}

///|
async test "remove_dir_recursive: removes directory and contents" {
  let tmp = create_temp_dir("indexion-test")
  let sub = path_join(tmp, "sub")
  ensure_dir_async(sub)
  write_bytes_async(path_join(sub, "file.txt"), b"data")
  remove_dir_recursive(tmp)
  let exists = path_exists_async(tmp)
  assert_false(exists)
}

///|
async test "ensure_dir_async: creates nested directory" {
  let tmp = create_temp_dir("indexion-test")
  let nested = path_join(tmp, "a/b/c")
  ensure_dir_async(nested)
  let exists = path_exists_async(nested)
  assert_true(exists)
  remove_dir_recursive(tmp)
}
