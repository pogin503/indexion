///|
/// Shared digest workspace operations.
///
/// This package is the SoT for locating, loading, freshness-checking, and
/// incrementally updating a digest index for a source workspace.

///|
pub struct GraphBuildResult {
  graph : @graph.CodeGraph
  /// Map of file path -> content hash for all analyzed files.
  file_hashes : Map[String, @cas_types.ContentHash]
}

///|
pub struct UpdateResult {
  indexed_count : Int
  skipped_count : Int
  removed_count : Int
  saved : Bool
  save_errors : Array[String]
}

///|
pub fn resolve_index_dir(workspace_dir : String) -> String? {
  @config.resolve_project_indexion_dir(workspace_dir, "digest")
}

///|
pub fn resolve_workspace_dir(workspace_dir : String) -> String {
  match @config.find_project_root_from(workspace_dir) {
    Some(root) => root
    None => @config.normalize_path(workspace_dir)
  }
}

///|
pub fn resolve_source_dir_for_index(
  requested_dir : String,
  index_dir : String,
) -> String {
  let source_dir = @config.normalize_path(requested_dir)
  match @config.find_project_root_from(source_dir) {
    Some(root) =>
      match resolve_index_dir(root) {
        Some(project_index_dir) =>
          if @config.normalize_path(project_index_dir) ==
            @config.normalize_path(index_dir) {
            root
          } else {
            source_dir
          }
        None => source_dir
      }
    None => source_dir
  }
}

///|
pub fn index_files_exist(index_dir : String) -> Bool {
  @fs.path_exists(@dconfig.manifest_path(index_dir)) &&
  @fs.path_exists(@dconfig.graph_path(index_dir))
}

///|
pub fn load_graph(index_dir : String) -> @graph.CodeGraph? {
  let graph_path = @dconfig.graph_path(index_dir)
  let graph_json = @fs.read_file_to_string(graph_path) catch {
    _ => return None
  }
  @graph.CodeGraph::from_json_string(graph_json)
}

///|
pub fn load_index_with_graph(
  index_dir : String,
  digest_config : @dconfig.DigestConfig,
) -> @index.DigestIndex? {
  if !index_files_exist(index_dir) {
    return None
  }
  let graph = match load_graph(index_dir) {
    Some(g) => g
    None => return None
  }
  Some(@index.DigestIndex::load_with_graph(index_dir, digest_config, graph))
}

///|
pub fn is_indexion_generated_path(path : String) -> Bool {
  path == ".indexion" ||
  path.has_prefix(".indexion/") ||
  path.has_suffix("/.indexion") ||
  path.contains("/.indexion/")
}

///|
pub fn has_relevant_changed_path(paths : Array[String]) -> Bool {
  for path in paths {
    if !is_indexion_generated_path(path) {
      return true
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
    if is_indexion_generated_path(path) {
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
pub async fn may_be_stale(workspace_dir : String, index_dir : String) -> Bool {
  if !index_files_exist(index_dir) {
    return true
  }
  let index_mtime = match
    @git.file_mtime_seconds(@dconfig.manifest_path(index_dir)) {
    Some(t) => t
    None => return true
  }
  match @git.repo_root(workspace_dir) {
    Some(repo_root) => {
      match @git.worktree_changed_files(repo_root, [workspace_dir]) {
        Some(files) =>
          if has_changed_path_newer_than(repo_root, files, index_mtime) {
            return true
          }
        None => return true
      }
      match @git.last_commit_seconds(repo_root, workspace_dir) {
        Some(seconds) => seconds > index_mtime
        None => true
      }
    }
    None =>
      match @git.file_mtime_seconds(workspace_dir) {
        Some(seconds) => seconds > index_mtime
        None => true
      }
  }
}

///|
pub fn build_graph_from_source(
  source_dir : String,
  specs_dir : String,
  progress? : ((Int, Int, String)) -> Unit = fn(_info) { () },
) -> GraphBuildResult? {
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir~,
    target_dir=source_dir,
  )
  let kgf_ignore = registry.collect_ignore_patterns()
  let discover_opts = @pipeline.DiscoverOptions::new(
    kgf_ignore~,
    root_dir=source_dir,
  )
  let paths = @pipeline.discover_files([source_dir], discover_opts)
  if paths.length() == 0 {
    return None
  }
  let files = @pipeline.collect_supported_files(paths, registry)
  if files.length() == 0 {
    return None
  }
  let file_hashes : Map[String, @cas_types.ContentHash] = {}
  for entry in files {
    let path = entry.0
    let content = entry.1
    file_hashes.set(path, @cas_hash.compute_hash(content))
  }
  let progress_callback = @build.ProgressCallback::new(progress)
  let doc_config = @build.DocConfig::new(files, registry.to_specs_map())
  let (_, graph) = @build.build_with_graph_progress(
    doc_config,
    Some(progress_callback),
  )
  Some({ graph, file_hashes })
}

///|
pub async fn update_index(
  workspace_dir : String,
  index_dir : String,
  specs_dir : String,
  digest_config : @dconfig.DigestConfig,
  progress? : ((Int, Int, String)) -> Unit = fn(_info) { () },
) -> UpdateResult? {
  let build_result = match
    build_graph_from_source(workspace_dir, specs_dir, progress~) {
    Some(r) => r
    None => return None
  }
  let index = @index.DigestIndex::load_or_create(index_dir, digest_config)
  let file_hashes : Map[String, @cas_types.ContentHash]? = Some(
    build_result.file_hashes,
  )
  let result = index.build_with_config(
    build_result.graph,
    digest_config,
    file_hashes~,
  )
  let save_errors = if result.indexed_count > 0 || result.removed_count > 0 {
    index.save_to_dir(index_dir, build_result.graph)
  } else {
    []
  }
  Some({
    indexed_count: result.indexed_count,
    skipped_count: result.skipped_count,
    removed_count: result.removed_count,
    saved: save_errors.length() == 0 &&
    (result.indexed_count > 0 || result.removed_count > 0),
    save_errors,
  })
}

///|
pub async fn update_index_if_stale(
  workspace_dir : String,
  index_dir : String,
  specs_dir : String,
  digest_config : @dconfig.DigestConfig,
  progress? : ((Int, Int, String)) -> Unit = fn(_info) { () },
) -> UpdateResult? {
  if !may_be_stale(workspace_dir, index_dir) {
    return None
  }
  update_index(workspace_dir, index_dir, specs_dir, digest_config, progress~)
}
