///|
/// # Wiki Search Index I/O
///
/// Single Source of Truth for wiki search index persistence.
/// Two files are managed together in the wiki directory:
///   - vectors.db           — serialized vcdb (vector embeddings)
///   - search-sections.json — section metadata required to reconstruct WikiSearchHit

///|
/// File name for the serialized vector database.
pub const VECTORS_FILE : String = "vectors.db"

///|
/// File name for the serialized section metadata.
pub const SECTIONS_FILE : String = "search-sections.json"

///|
/// Persist a WikiSearchIndex to the wiki directory.
/// Writes both vectors.db and search-sections.json atomically (best-effort).
pub fn save(index : WikiSearchIndex, wiki_dir : String) -> Unit {
  let vectors_path = wiki_dir + "/" + VECTORS_FILE
  @fs.write_bytes_to_file(vectors_path, index.engine.serialize()) catch {
    e =>
      println(
        "Warning: failed to write " + VECTORS_FILE + ": " + e.to_string(),
      )
  }
  let sections_arr : Array[Json] = []
  for entry in index.sections {
    sections_arr.push(entry.1.to_json())
  }
  let sections_path = wiki_dir + "/" + SECTIONS_FILE
  @fs.write_string_to_file(
    sections_path,
    Json::array(sections_arr).stringify(indent=2),
  ) catch {
    e =>
      println(
        "Warning: failed to write " + SECTIONS_FILE + ": " + e.to_string(),
      )
  }
}

///|
/// Load a WikiSearchIndex from the wiki directory.
/// Returns None if either file is absent or cannot be parsed.
pub fn load(wiki_dir : String) -> WikiSearchIndex? {
  let vectors_path = wiki_dir + "/" + VECTORS_FILE
  let sections_path = wiki_dir + "/" + SECTIONS_FILE
  if not(@fs.path_exists(vectors_path)) || not(@fs.path_exists(sections_path)) {
    return None
  }
  let bytes = @fs.read_file_to_bytes(vectors_path) catch { _ => return None }
  let engine = @search_engine.SearchEngine::from_bytes(bytes)
  let sections_text = @fs.read_file_to_string(sections_path) catch {
    _ => return None
  }
  let sections_json = @json.parse(sections_text) catch { _ => return None }
  let section_list : Array[WikiSection] = @json.from_json!(sections_json) catch {
    _ => return None
  }
  let sections : Map[String, WikiSection] = {}
  for s in section_list {
    sections[s.id] = s
  }
  Some(WikiSearchIndex::{ engine, sections })
}

///|
/// Return true when a persisted wiki search index exists in wiki_dir.
pub fn exists(wiki_dir : String) -> Bool {
  @fs.path_exists(wiki_dir + "/" + VECTORS_FILE) &&
  @fs.path_exists(wiki_dir + "/" + SECTIONS_FILE)
}
