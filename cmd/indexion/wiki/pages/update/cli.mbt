///|
/// # indexion wiki pages update
///
/// Update an existing wiki page's content and metadata.

///|
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "update",
    about="Update an existing wiki page",
    options=[
      @argparse.OptionArg("id", about="Page ID to update"),
      @argparse.OptionArg(
        "content",
        about="Path to .md file with new page content",
      ),
      @argparse.OptionArg(
        "sources",
        about="Comma-separated source file paths (replaces existing)",
      ),
      @argparse.OptionArg(
        "provenance",
        about="Content provenance: extracted, synthesized, manual",
      ),
      @argparse.OptionArg(
        "actor",
        about="Who is updating: indexion, agent:<name>, user",
        default_values=["user"],
      ),
      @argparse.OptionArg(
        "wiki-dir",
        about="Wiki directory",
        default_values=[".indexion/wiki"],
      ),
    ],
  )
}

///|
pub fn run_matches(matches : @argparse.Matches) -> Unit {
  let id = match matches.values.get("id") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "" }
    _ => ""
  }
  let content_path = match matches.values.get("content") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "" }
    _ => ""
  }
  if id.length() == 0 || content_path.length() == 0 {
    println("Error: --id and --content are required.")
    println("Usage: indexion wiki pages update --id=<id> --content=<file.md>")
    return
  }
  let wiki_dir_resolved = match @common.resolve_wiki_dir(
    match matches.values.get("wiki-dir") {
      Some(arr) => if arr.length() > 0 { arr[0] } else { ".indexion/wiki" }
      _ => ".indexion/wiki"
    },
  ) {
    Some(dir) => dir
    None => {
      println("Error: Could not find project root directory.")
      return
    }
  }
  let sources_str = match matches.values.get("sources") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "" }
    _ => ""
  }
  let provenance : String? = match matches.values.get("provenance") {
    Some(arr) => if arr.length() > 0 { Some(arr[0]) } else { None }
    _ => None
  }
  let actor = match matches.values.get("actor") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "user" }
    _ => "user"
  }
  let content = @fs.read_file_to_string(content_path) catch {
    e => {
      println("Error reading content file: " + e.to_string())
      return
    }
  }
  let manifest = match @wiki_manifest.load_manifest(wiki_dir_resolved) {
    Some(m) => m
    None => return
  }
  let mut found = false
  let new_pages : Array[@wiki_types.ManifestPage] = []
  for mp in manifest.pages {
    if mp.id == id {
      found = true
      let new_sources : Array[String]? = if sources_str.length() > 0 {
        Some(@common.parse_comma_list(sources_str))
      } else {
        None
      }
      let new_provenance : String?? = match provenance {
        Some(_) => Some(provenance)
        None => None
      }
      let updated = match (new_sources, new_provenance) {
        (Some(s), Some(p)) =>
          mp.with_updates(sources=s, provenance=p, last_actor=Some(actor))
        (Some(s), None) => mp.with_updates(sources=s, last_actor=Some(actor))
        (None, Some(p)) => mp.with_updates(provenance=p, last_actor=Some(actor))
        (None, None) => mp.with_updates(last_actor=Some(actor))
      }
      new_pages.push(updated)
    } else {
      new_pages.push(mp)
    }
  }
  if !found {
    println("Error: Page with ID '" + id + "' not found in manifest.")
    return
  }
  let new_manifest = @wiki_types.WikiManifest::new(
    title=manifest.title,
    pages=new_pages,
  )
  if !@wiki_manifest.write_page(wiki_dir_resolved, new_manifest, id, content) {
    return
  }
  println("Updated page '" + id + "'")
  let log = @wiki_log.WikiLog::load(wiki_dir_resolved)
  log.append(
    @wiki_log.WikiLogEntry::new(
      timestamp=@env.now(),
      operation="pages update",
      actor=actor,
      summary="Updated page: " + id,
      affected_pages=[id],
    ),
  )
  log.save(wiki_dir_resolved)
}
