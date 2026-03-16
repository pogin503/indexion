///|
fn fork_native() -> Int {
  -1
}

///|
fn waitpid_native(_pid : Int) -> Int {
  -1
}

///|
fn exit_now(_code : Int) -> Unit {

}

///|
fn getpid_native() -> Int {
  -1
}

///|
fn flush_stdio_native() -> Unit {

}

///|
fn mkdir_native(_path : String) -> Int {
  -1
}

///|
fn unlink_native(_path : String) -> Int {
  -1
}

///|
fn rmdir_native(_path : String) -> Int {
  -1
}

///|
fn cpu_count_native() -> Int {
  1
}

///|
fn parallel_available_native() -> Bool {
  false
}
