///|
pub fn cache_path(dir : String, file_name : String) -> String {
  dir + "/" + file_name
}

///|
pub fn ensure_cache_dir(cache_dir : String, label : String) -> Bool {
  if @fs.path_exists(cache_dir) {
    let is_dir = @fs.is_dir(cache_dir) catch {
      err => {
        println(
          "Error: failed to inspect " +
          label +
          " `" +
          cache_dir +
          "`: " +
          err.to_string(),
        )
        return false
      }
    }
    if !is_dir {
      println(
        "Error: " +
        label +
        " `" +
        cache_dir +
        "` exists and is not a directory.",
      )
      return false
    }
  }
  @config.ensure_dir_recursive(cache_dir)
  true
}

///|
pub fn write_json_file(path : String, json : Json, label : String) -> Bool {
  @fs.write_string_to_file(path, json.stringify(indent=2)) catch {
    err => {
      println(
        "Error: failed to write " +
        label +
        " `" +
        path +
        "`: " +
        err.to_string(),
      )
      return false
    }
  }
  true
}

///|
pub fn read_json_file(path : String, label : String) -> Json? {
  let text = @fs.read_file_to_string(path) catch {
    err => {
      println(
        "Error: failed to read " + label + " `" + path + "`: " + err.to_string(),
      )
      return None
    }
  }
  let json : Json = @json.parse(text) catch {
    err => {
      println(
        "Error: failed to parse " +
        label +
        " `" +
        path +
        "`: " +
        err.to_string(),
      )
      return None
    }
  }
  Some(json)
}
