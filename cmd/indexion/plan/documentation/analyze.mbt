///|
/// Documentation analysis - extract doc coverage from MoonBit files.

///|
/// Project info from moon.mod.json.
pub struct ProjectInfo {
  name : String
  version : String
  description : String
  repository : String
  license : String
  keywords : Array[String]
}

///|
pub fn ProjectInfo::default() -> ProjectInfo {
  {
    name: "project",
    version: "0.0.0",
    description: "",
    repository: "",
    license: "",
    keywords: [],
  }
}

///|
/// A public item (function, type, etc.) found in the code.
pub struct PubItem {
  name : String
  kind : String // "fn", "type", "struct", "enum", "trait"
  file : String
  line : Int
  has_doc : Bool
  doc_preview : String // first line of doc if exists
}

///|
/// Package-level documentation analysis.
pub struct PackageAnalysis {
  path : String
  files : Array[String]
  pub_items : Array[PubItem]
  total_pub : Int
  documented : Int
  has_readme : Bool
}

///|
/// Full documentation analysis result.
pub struct DocAnalysis {
  packages : Array[PackageAnalysis]
  total_pub_items : Int
  total_documented : Int
  coverage_percent : Double
  critical_missing : Array[PubItem] // high priority undocumented
}

///|
/// Load project info from moon.mod.json.
pub fn load_project_info(dir : String) -> ProjectInfo {
  let path = @common.normalize_path(dir) + "/moon.mod.json"
  try {
    let content = @fs.read_file_to_string(path)
    parse_moon_mod_json(content)
  } catch {
    _ => ProjectInfo::default()
  }
}

///|
fn parse_moon_mod_json(content : String) -> ProjectInfo {
  let mut info = ProjectInfo::default()
  // Simple JSON parsing for specific fields
  info = { ..info, name: @common.extract_json_string(content, "name") }
  info = { ..info, version: @common.extract_json_string(content, "version") }
  info = {
    ..info,
    description: @common.extract_json_string(content, "description"),
  }
  info = {
    ..info,
    repository: @common.extract_json_string(content, "repository"),
  }
  info = { ..info, license: @common.extract_json_string(content, "license") }
  info = { ..info, keywords: @common.extract_json_array(content, "keywords") }
  info
}

// extract_json_string, extract_json_array: use @common (SoT)

///|
/// Analyze documentation coverage in directory.
pub fn analyze_documentation(
  dir : String,
  specs_dir? : String = "kgfs",
) -> DocAnalysis {
  let packages : Array[PackageAnalysis] = []
  let all_items : Array[PubItem] = []
  let normalized_dir = @common.normalize_path(dir)
  let base_filter = @pipeline.build_filter_from_root(normalized_dir)
  let registry = @kgf_features.load_registry(
    specs_dir~,
    target_dir=normalized_dir,
  )
  // Apply KGF ignore patterns (e.g. *_test.mbt, *_wbtest.mbt)
  let filter = match registry {
    Some(reg) => {
      let kgf_ignore = reg.collect_ignore_patterns()
      // Group patterns by language
      let by_lang : Map[String, Array[String]] = {}
      for pair in kgf_ignore {
        let (pattern, lang) = pair
        match by_lang.get(lang) {
          Some(arr) => arr.push(pattern)
          None => by_lang.set(lang, [pattern])
        }
      }
      let mut f = base_filter
      for entry in by_lang {
        f = f.with_kgf_ignore(entry.1, entry.0)
      }
      f
    }
    None => base_filter
  }
  collect_packages(normalized_dir, packages, "", filter, registry)
  // Aggregate stats
  let mut total_pub = 0
  let mut total_doc = 0
  for pkg in packages {
    total_pub = total_pub + pkg.total_pub
    total_doc = total_doc + pkg.documented
    for item in pkg.pub_items {
      all_items.push(item)
    }
  }
  let coverage = if total_pub > 0 {
    total_doc.to_double() / total_pub.to_double() * 100.0
  } else {
    100.0
  }
  // Find critical missing (pub fn/type without docs)
  let critical : Array[PubItem] = []
  for item in all_items {
    if !item.has_doc &&
      (item.kind == "fn" || item.kind == "type" || item.kind == "struct") {
      critical.push(item)
    }
  }
  // Sort critical by file
  sort_pub_items(critical)
  {
    packages,
    total_pub_items: total_pub,
    total_documented: total_doc,
    coverage_percent: coverage,
    critical_missing: critical,
  }
}

///|
/// Check if a filename matches any of the given extensions.
fn has_registered_extension(
  filename : String,
  extensions : Array[String],
) -> Bool {
  for ext in extensions {
    if filename.has_suffix(ext) {
      return true
    }
  }
  false
}

///|
/// Check if a filename matches any of the given package marker names.
fn is_package_marker(filename : String, markers : Array[String]) -> Bool {
  for marker in markers {
    if filename == marker {
      return true
    }
  }
  false
}

///|
fn collect_packages(
  dir : String,
  packages : Array[PackageAnalysis],
  rel_path : String,
  filter : @filter.FilterConfig,
  registry : @kgf_registry.KGFRegistry?,
) -> Unit {
  try {
    if !@fs.is_dir(dir) {
      return
    }
    // Get extensions and package markers from KGF registry
    let extensions = match registry {
      Some(reg) => reg.get_extensions()
      None => []
    }
    let pkg_markers = match registry {
      Some(reg) => reg.get_package_markers()
      None => []
    }
    // Load nested .gitignore/.indexionignore if present
    let local_filter = filter
      .with_gitignore_from_dir(dir, @vcs_git.GITIGNORE_FILENAME)
      .with_indexionignore_from_dir(dir, @config.INDEXIONIGNORE_FILENAME)
    let entries = @fs.read_dir(dir)
    let source_files : Array[String] = []
    let mut has_package_marker = false
    let mut has_readme = false
    for entry in entries {
      let path = dir + "/" + entry
      if is_package_marker(entry, pkg_markers) {
        has_package_marker = true
      } else if entry.has_prefix("README") {
        has_readme = true
      } else if has_registered_extension(entry, extensions) {
        let file_rel = if rel_path.length() > 0 {
          rel_path + "/" + entry
        } else {
          entry
        }
        match local_filter.should_include(file_rel, false) {
          @filter.FilterResult::Include => source_files.push(entry)
          @filter.FilterResult::Exclude(_) => ()
        }
      } else if @fs.is_dir(path) {
        if !local_filter.should_skip_dir(entry) {
          let sub_rel = if rel_path.length() > 0 {
            rel_path + "/" + entry
          } else {
            entry
          }
          collect_packages(path, packages, sub_rel, local_filter, registry)
        }
      }
    }
    // Analyze this package if it has source files and a package marker
    if source_files.length() > 0 && has_package_marker {
      let pkg_path = if rel_path.length() > 0 { rel_path } else { "." }
      let pub_items : Array[PubItem] = []
      for file in source_files {
        let file_path = dir + "/" + file
        let file_rel = if rel_path.length() > 0 {
          rel_path + "/" + file
        } else {
          file
        }
        analyze_source_file(file_path, file_rel, pub_items, registry)
      }
      let documented = pub_items
        .iter()
        .filter(fn(i) { i.has_doc })
        .fold(init=0, fn(acc, _) { acc + 1 })
      packages.push({
        path: pkg_path,
        files: source_files,
        pub_items,
        total_pub: pub_items.length(),
        documented,
        has_readme,
      })
    }
  } catch {
    _ => ()
  }
}

///|
/// Analyze source file for public declarations using KGF tokenization.
/// Associates doc comments with declarations via single-pass KGF token extraction.
fn analyze_source_file(
  path : String,
  rel_path : String,
  items : Array[PubItem],
  registry : @kgf_registry.KGFRegistry?,
) -> Unit {
  try {
    let content = @fs.read_file_to_string(path)
    // Extract both declarations and doc map in a single tokenization pass
    let (declarations, doc_map) = @kgf_features.extract_pub_declarations_and_doc_map(
      content, path, registry,
    )
    if declarations.length() == 0 {
      return
    }
    // Associate declarations with their doc comments
    for decl in declarations {
      let doc_lines = match doc_map.get(decl.line) {
        Some(doc) => @common.split_lines(doc)
        None => []
      }
      items.push(make_pub_item(decl, rel_path, doc_lines))
    }
  } catch {
    _ => ()
  }
}

///|
fn make_pub_item(
  decl : @kgf_features.PubDeclaration,
  file : String,
  doc_lines : Array[String],
) -> PubItem {
  let has_doc = doc_lines.length() > 0
  let doc_preview = if has_doc && doc_lines[0].length() > 0 {
    let preview = doc_lines[0]
    if preview.length() > 60 {
      @common.substring(preview, 0, 60) + "..."
    } else {
      preview
    }
  } else {
    ""
  }
  {
    name: decl.name,
    kind: decl.kind,
    file,
    line: decl.line,
    has_doc,
    doc_preview,
  }
}

// extract_identifier, is_ident_char: no longer needed (KGF handles identification)
// use @common (SoT) — split_lines

// use @common (SoT) — trim_ascii_spaces, substring, normalize_path

///|
fn sort_pub_items(items : Array[PubItem]) -> Unit {
  items.sort_by(fn(a, b) {
    let cmp = a.file.compare(b.file)
    if cmp != 0 {
      cmp
    } else {
      a.line.compare(b.line)
    }
  })
}
