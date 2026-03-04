///|
/// Package discovery using KGF registry for language detection.

///|
/// Information about a discovered package.
pub struct PackageInfo {
  path : String
  name : String
  files : Array[String]
}

///|
pub fn PackageInfo::new(
  path : String,
  name : String,
  files : Array[String],
) -> PackageInfo {
  { path, name, files }
}

///|
/// Discover packages from given paths using KGF registry.
pub fn discover_packages(
  registry : @registry.KGFRegistry,
  paths : Array[String],
  includes : Array[String],
  excludes : Array[String],
  recursive : Bool,
) -> Array[PackageInfo] {
  let packages : Array[PackageInfo] = []
  for path in paths {
    let clean_path = trim_trailing_slash(path)
    discover_impl(registry, clean_path, includes, excludes, recursive, packages)
  }
  packages
}

///|
fn discover_impl(
  registry : @registry.KGFRegistry,
  path : String,
  includes : Array[String],
  excludes : Array[String],
  recursive : Bool,
  packages : Array[PackageInfo],
) -> Unit {
  try {
    if not(@fs.is_dir(path)) {
      return
    }
    // Collect supported files in this directory
    let files = collect_supported_files(registry, path)
    if files.length() > 0 {
      let name = extract_dir_name(path)
      if should_include(path, includes, excludes) {
        packages.push(PackageInfo::new(path, name, files))
      }
    }
    // Recurse into subdirectories
    if recursive {
      let entries = @fs.read_dir(path)
      for entry in entries {
        // Skip hidden directories only
        if entry.has_prefix(".") {
          continue
        }
        let subpath = path + "/" + entry
        if @fs.is_dir(subpath) {
          discover_impl(registry, subpath, includes, excludes, recursive, packages)
        }
      }
    }
  } catch {
    _ => ()
  }
}

///|
/// Collect files supported by KGF registry in a directory.
fn collect_supported_files(
  registry : @registry.KGFRegistry,
  dir : String,
) -> Array[String] {
  let files : Array[String] = []
  try {
    let entries = @fs.read_dir(dir)
    for entry in entries {
      let path = dir + "/" + entry
      if @fs.is_file(path) && registry.is_file_supported(path) {
        files.push(path)
      }
    }
  } catch {
    _ => ()
  }
  files
}

///|
/// Extract directory name from path.
fn extract_dir_name(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash >= 0 && last_slash < chars.length() - 1 {
    let result : Array[Char] = []
    for i = last_slash + 1; i < chars.length(); i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    path
  }
}

///|
fn trim_trailing_slash(path : String) -> String {
  if path.length() > 0 && path.has_suffix("/") {
    let chars = path.to_array()
    let result : Array[Char] = []
    for i = 0; i < chars.length() - 1; i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    path
  }
}

///|
/// Check if path should be included based on include/exclude patterns.
fn should_include(
  path : String,
  includes : Array[String],
  excludes : Array[String],
) -> Bool {
  // Check excludes first
  for pattern in excludes {
    if matches_pattern(path, pattern) {
      return false
    }
  }
  // If no includes specified, include all (that weren't excluded)
  if includes.length() == 0 {
    return true
  }
  // Check includes
  for pattern in includes {
    if matches_pattern(path, pattern) {
      return true
    }
  }
  false
}

///|
/// Check if string matches a glob pattern (simple implementation).
pub fn matches_pattern(text : String, pattern : String) -> Bool {
  let text_chars = text.to_array()
  let pat_chars = pattern.to_array()
  matches_impl(text_chars, 0, pat_chars, 0)
}

///|
fn matches_impl(
  text : Array[Char],
  ti : Int,
  pat : Array[Char],
  pi : Int,
) -> Bool {
  if ti >= text.length() && pi >= pat.length() {
    return true
  }
  if pi >= pat.length() {
    return false
  }
  if pat[pi] == '*' {
    if matches_impl(text, ti, pat, pi + 1) {
      return true
    }
    if ti < text.length() {
      return matches_impl(text, ti + 1, pat, pi)
    }
    return false
  }
  if ti >= text.length() {
    return false
  }
  if pat[pi] == text[ti] {
    return matches_impl(text, ti + 1, pat, pi + 1)
  }
  false
}
