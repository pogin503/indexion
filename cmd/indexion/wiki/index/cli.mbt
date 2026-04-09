///|
/// # indexion wiki index
///
/// Manage the wiki index: navigation catalog and vector search index.
///
/// ## Subcommands
///
/// - `build` - Build nav index (index.md) and optionally vector index (vectors.db)

///|
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "index",
    about="Manage wiki index (navigation catalog + search vectors)",
    subcommand_required=true,
    subcommands=[build_command()],
  )
}

///|
pub async fn dispatch(matches : @argparse.Matches) -> Unit {
  guard matches.subcommand is Some((name, sub)) else { return }
  match name {
    "build" => run_build(sub)
    _ => ()
  }
}

///|
fn build_command() -> @argparse.Command {
  @argparse.Command(
    "build",
    about="Build wiki index (index.md + optionally vectors.db)",
    flags=[
      @argparse.FlagArg(
        "dry-run",
        about="Output index.md to stdout instead of writing to wiki",
      ),
      @argparse.FlagArg(
        "full",
        about="Also build vector search index (vectors.db + search-sections.json)",
      ),
    ],
    options=[
      @argparse.OptionArg(
        "wiki-dir",
        about="Wiki directory",
        default_values=[".indexion/wiki"],
      ),
      @argparse.OptionArg("output", short='o', about="Output file path"),
      @argparse.OptionArg("specs-dir", about=@help.specs_dir, default_values=[
        "kgfs",
      ]),
    ],
  )
}

///|
async fn run_build(matches : @argparse.Matches) -> Unit {
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
  let output = match matches.values.get("output") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "" }
    _ => ""
  }
  let specs_dir = match matches.values.get("specs-dir") {
    Some(arr) => if arr.length() > 0 { arr[0] } else { "kgfs" }
    _ => "kgfs"
  }
  let dry_run = match matches.flags.get("dry-run") {
    Some(v) => v
    _ => false
  }
  let full = match matches.flags.get("full") {
    Some(v) => v
    _ => false
  }
  // Load wiki
  let registry = @kgf_features.load_registry(
    specs_dir=specs_dir,
    target_dir=".",
  )
  let wiki = match @wiki_reader.load_wiki(wiki_dir_resolved, registry~) {
    Some(w) => w
    None => {
      println("Error: No wiki found at " + wiki_dir_resolved)
      return
    }
  }
  // Load log for recent changes
  let log = @wiki_log.WikiLog::load(wiki_dir_resolved)
  let log_opt : @wiki_log.WikiLog? = if log.length() > 0 {
    Some(log)
  } else {
    None
  }
  // Build navigation index
  let index = @wiki_index.build_index(wiki, log_opt)
  let content = index.to_markdown()
  if dry_run || output.length() > 0 {
    @common.write_output(output, content, label="Wiki index")
  } else {
    let index_path = wiki_dir_resolved + "/index.md"
    @fs.write_string_to_file(index_path, content) catch {
      e => {
        println("Error writing index.md: " + e.to_string())
        return
      }
    }
    println(
      "Built index.md: " +
      index.total_pages.to_string() +
      " pages, " +
      index.categories.length().to_string() +
      " categories",
    )
  }
  // Build vector search index if --full
  if full {
    println("Building vector search index...")
    let provider : @embed_config.EmbeddingProvider = @embed_config.TfIdf(256)
    let search_index = @wiki_search.build_search_index(
      wiki.pages,
      provider,
      registry~,
    ) catch {
      @embed.ParseError(msg) => {
        println("Error building search index: " + msg)
        return
      }
      @embed.ApiError(code, msg) => {
        println(
          "Error building search index (API " + code.to_string() + "): " + msg,
        )
        return
      }
      @embed.NoResult => {
        println("Error building search index: no embedding result")
        return
      }
    }
    search_index.save(wiki_dir_resolved)
    println(
      "Built vectors.db: " +
      search_index.sections.length().to_string() +
      " sections",
    )
  }
  // Log the operation
  let op_log = @wiki_log.WikiLog::load(wiki_dir_resolved)
  op_log.append(
    @wiki_log.WikiLogEntry::new(
      timestamp=@env.now(),
      operation="index build",
      actor="indexion",
      summary="Built index: " +
        index.categories.length().to_string() +
        " categories, " +
        index.hub_pages.length().to_string() +
        " hub pages" +
        (if full { " + vectors" } else { "" }),
    ),
  )
  op_log.save(wiki_dir_resolved)
}
