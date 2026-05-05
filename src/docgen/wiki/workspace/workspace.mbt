///|
/// Shared wiki workspace operations.
///
/// This package is the SoT for locating wiki directories, checking freshness of
/// persisted wiki search indexes, and rebuilding them when needed.

///|
pub struct SearchUpdateResult {
  sections_count : Int
  saved : Bool
}

///|
pub fn resolve_wiki_dir(anchor_dir : String) -> String? {
  let normalized = @config.normalize_path(anchor_dir)
  if @fs.path_exists(@wiki_types.wiki_manifest_path(normalized)) {
    Some(normalized)
  } else if normalized.has_suffix(".indexion/wiki") ||
    normalized.has_suffix(".indexion/wiki/") {
    let base = if normalized.has_suffix(".indexion/wiki/") {
      @config.substring(normalized, 0, normalized.to_array().length() - 15)
    } else {
      @config.substring(normalized, 0, normalized.to_array().length() - 14)
    }
    let resolved_base = if base.length() == 0 { "." } else { base }
    @config.resolve_project_indexion_dir(resolved_base, "wiki")
  } else {
    @config.resolve_project_indexion_dir(normalized, "wiki")
  }
}

///|
pub fn is_wiki_dir(wiki_dir : String) -> Bool {
  @fs.path_exists(@wiki_types.wiki_manifest_path(wiki_dir))
}

///|
pub fn index_files_exist(wiki_dir : String) -> Bool {
  @wiki_search.exists(wiki_dir)
}

///|
pub fn is_wiki_search_generated_path(path : String) -> Bool {
  path.has_suffix("/" + @wiki_search.VECTORS_FILE) ||
  path.has_suffix("/" + @wiki_search.SECTIONS_FILE) ||
  path.has_suffix("/" + @wiki_search.VOCABULARY_FILE) ||
  path.has_suffix("/index.md")
}

///|
fn load_manifest(wiki_dir : String) -> @wiki_types.WikiManifest? {
  let text = @fs.read_file_to_string(@wiki_types.wiki_manifest_path(wiki_dir)) catch {
    _ => return None
  }
  let json : Json = @json.parse(text) catch { _ => return None }
  let manifest : @wiki_types.WikiManifest = @json.from_json(json) catch {
    _ => return None
  }
  Some(manifest)
}

///|
pub fn wiki_content_paths(wiki_dir : String) -> Array[String]? {
  let manifest = match load_manifest(wiki_dir) {
    Some(m) => m
    None => return None
  }
  let paths : Array[String] = [@wiki_types.wiki_manifest_path(wiki_dir)]
  for page in manifest.pages {
    if page.file.length() > 0 {
      paths.push(@config.join_path(wiki_dir, page.file))
    }
  }
  Some(paths)
}

///|
async fn has_content_path_newer_than(
  paths : Array[String],
  timestamp : Int,
) -> Bool {
  for path in paths {
    match @git.file_mtime_seconds(path) {
      Some(seconds) => if seconds > timestamp { return true }
      None => return true
    }
  }
  false
}

///|
async fn has_changed_path_newer_than(
  repo_root : String,
  paths : Array[String],
  timestamp : Int,
) -> Bool {
  for path in paths {
    if is_wiki_search_generated_path(path) {
      continue
    }
    let full_path = @config.join_path(repo_root, path)
    match @git.file_mtime_seconds(full_path) {
      Some(seconds) => if seconds > timestamp { return true }
      None => return true
    }
  }
  false
}

///|
pub async fn may_be_stale(wiki_dir : String) -> Bool {
  if !index_files_exist(wiki_dir) {
    return true
  }
  let index_mtime = match
    @git.file_mtime_seconds(
      @config.join_path(wiki_dir, @wiki_search.SECTIONS_FILE),
    ) {
    Some(t) => t
    None => return true
  }
  let content_paths = match wiki_content_paths(wiki_dir) {
    Some(paths) => paths
    None => return true
  }
  if has_content_path_newer_than(content_paths, index_mtime) {
    return true
  }
  match @git.repo_root(wiki_dir) {
    Some(repo_root) => {
      match @git.worktree_changed_files(repo_root, [wiki_dir]) {
        Some(files) =>
          if has_changed_path_newer_than(repo_root, files, index_mtime) {
            return true
          }
        None => return true
      }
      match @git.last_commit_seconds(repo_root, wiki_dir) {
        Some(seconds) => seconds > index_mtime
        None => false
      }
    }
    None => false
  }
}

///|
pub async fn update_search_index(
  wiki_dir : String,
  specs_dir : String,
  provider : @embed_config.EmbeddingProvider,
) -> SearchUpdateResult? raise @embed.EmbedError {
  let registry = @kgf_features.load_registry(specs_dir~, target_dir=wiki_dir)
  let wiki = match @wiki_reader.load_wiki(wiki_dir, registry~) {
    Some(w) => w
    None => return None
  }
  let index = @wiki_search.build_search_index(wiki.pages, provider, registry~)
  index.save(wiki_dir)
  Some({ sections_count: index.sections.length(), saved: true })
}

///|
pub async fn update_search_index_if_stale(
  wiki_dir : String,
  specs_dir : String,
  provider : @embed_config.EmbeddingProvider,
) -> SearchUpdateResult? {
  if !may_be_stale(wiki_dir) {
    return None
  }
  update_search_index(wiki_dir, specs_dir, provider) catch {
    _ => None
  }
}
