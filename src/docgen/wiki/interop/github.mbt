///|
/// # GitHub Wiki Backend
///
/// GitHub Wiki format: Home.md, _Sidebar.md, [[wiki links]], flat file structure.
/// Uses the github-wiki KGF spec for tokenization and link parsing.

///|
/// Load a GitHub Wiki directory into @types.WikiData.
pub fn load_github_wiki(wiki_dir : String) -> @types.WikiData? {
  let spec = match load_wiki_spec("github-wiki") {
    Some(s) => s
    None => {
      println(
        "Warning: github-wiki KGF spec not found. Ensure kgfs/ directory is accessible.",
      )
      return None
    }
  }
  let files = list_md_files(wiki_dir, spec.special_files)
  if files.is_empty() {
    return None
  }
  let filename_to_id : Map[String, String] = {}
  for f in files {
    filename_to_id[f] = github_filename_to_id(f)
  }
  let sidebar_path = wiki_dir + "/" + spec.nav_file
  let sidebar_content = @fs.read_file_to_string(sidebar_path) catch { _ => "" }
  let (nav_items, sidebar_titles) = if sidebar_content.length() > 0 {
    parse_sidebar_kgf(
      sidebar_content, filename_to_id, github_filename_to_id, title_to_github_filename,
      spec,
    )
  } else {
    let items : Array[@types.WikiNavItem] = []
    let titles : Map[String, String] = {}
    for f in files {
      let id = filename_to_id.get(f).unwrap_or(github_filename_to_id(f))
      let title = github_filename_to_title(f)
      items.push(@types.WikiNavItem::new(id~, title~))
      titles[id] = title
    }
    (items, titles)
  }
  let pages : Map[String, @types.WikiPage] = {}
  for f in files {
    let id = filename_to_id.get(f).unwrap_or(github_filename_to_id(f))
    let title = sidebar_titles.get(id).unwrap_or(github_filename_to_title(f))
    let raw_content = @fs.read_file_to_string(wiki_dir + "/" + f + ".md") catch {
      _ => ""
    }
    let (content_without_meta, source_strings) = extract_sources_kgf(
      raw_content, spec,
    )
    let content = convert_wikilinks_to_internal(
      content_without_meta, filename_to_id, github_filename_to_id, title_to_github_filename,
      spec,
    )
    let sources = parse_source_strings(source_strings)
    let headings = @reader.extract_headings(content)
    let children = find_children_for(id, nav_items)
    let parent = find_parent_in_nav(id, nav_items)
    pages[id] = @types.WikiPage::new(
      id~,
      title~,
      content~,
      sources~,
      headings~,
      children~,
      parent~,
    )
  }
  let nav = @types.WikiNav::new(pages=nav_items)
  Some(@types.WikiData::new(nav~, pages~))
}

///|
/// Export @types.WikiData to GitHub Wiki format.
pub fn export_github_wiki(data : @types.WikiData) -> Array[(String, String)] {
  let spec = match load_wiki_spec("github-wiki") {
    Some(s) => s
    None => {
      println("Warning: github-wiki KGF spec not found.")
      return []
    }
  }
  let home_name = strip_md_ext(spec.home_file)
  let result : Array[(String, String)] = []
  let id_to_title : Map[String, String] = {}
  let id_to_ghname : Map[String, String] = {}
  let root_id = find_root_id(data.nav)
  for entry in data.pages {
    let id = entry.0
    let page = entry.1
    id_to_title[id] = page.title
    let ghname = if id == root_id {
      home_name
    } else {
      title_to_github_filename(page.title)
    }
    id_to_ghname[id] = ghname
  }
  for entry in data.pages {
    let id = entry.0
    let page = entry.1
    let ghname = id_to_ghname
      .get(id)
      .unwrap_or(title_to_github_filename(page.title))
    let converted = convert_internal_to_wikilinks(
      page.content,
      id_to_ghname,
      id_to_title,
    )
    let sources_comment = embed_sources_comment(page.sources)
    let full_content = if sources_comment.length() > 0 {
      sources_comment + "\n" + converted
    } else {
      converted
    }
    result.push((ghname + ".md", full_content))
  }
  let sidebar = render_sidebar_wikilinks(
    data.nav,
    id_to_ghname,
    id_to_title,
    root_id,
    home_name,
  )
  result.push((spec.nav_file, sidebar))
  result
}

// --- GitHub-specific filename/ID helpers ---

///|
fn title_to_github_filename(title : String) -> String {
  let buf = StringBuilder::new()
  for c in title {
    if c == ' ' || c == '/' {
      buf.write_char('-')
    } else if c == '(' ||
      c == ')' ||
      c == '&' ||
      c == ':' ||
      c == '*' ||
      c == '?' ||
      c == '"' ||
      c == '<' ||
      c == '>' ||
      c == '|' ||
      c == '\\' {
      continue
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn github_filename_to_id(filename : String) -> String {
  let buf = StringBuilder::new()
  for c in filename {
    if c >= 'A' && c <= 'Z' {
      buf.write_char((c.to_int() + 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn github_filename_to_title(filename : String) -> String {
  let buf = StringBuilder::new()
  for c in filename {
    if c == '-' {
      buf.write_char(' ')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}
