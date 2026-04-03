///|
/// # GitLab Wiki Backend
///
/// GitLab Wiki format: home.md (lowercase), _sidebar.md, [[wiki links]],
/// nested directory structure supported.
/// Uses the gitlab-wiki KGF spec for tokenization and link parsing.

///|
/// Load a GitLab Wiki directory into @types.WikiData.
pub fn load_gitlab_wiki(wiki_dir : String) -> @types.WikiData? {
  let spec = match load_wiki_spec("gitlab-wiki") {
    Some(s) => s
    None => {
      println(
        "Warning: gitlab-wiki KGF spec not found. Ensure kgfs/ directory is accessible.",
      )
      return None
    }
  }
  let files = list_md_files_recursive(wiki_dir, spec.special_files)
  if files.is_empty() {
    return None
  }
  let slug_to_id : Map[String, String] = {}
  for f in files {
    slug_to_id[f] = gitlab_slug_to_id(f)
  }
  let sidebar_path = wiki_dir + "/" + spec.nav_file
  let sidebar_content = @fs.read_file_to_string(sidebar_path) catch { _ => "" }
  let (nav_items, sidebar_titles) = if sidebar_content.length() > 0 {
    parse_sidebar_kgf(
      sidebar_content, slug_to_id, gitlab_slug_to_id, title_to_gitlab_slug, spec,
    )
  } else {
    let items : Array[@types.WikiNavItem] = []
    let titles : Map[String, String] = {}
    for f in files {
      let id = slug_to_id.get(f).unwrap_or(gitlab_slug_to_id(f))
      let title = gitlab_slug_to_title(f)
      items.push(@types.WikiNavItem::new(id~, title~))
      titles[id] = title
    }
    (items, titles)
  }
  let pages : Map[String, @types.WikiPage] = {}
  for f in files {
    let id = slug_to_id.get(f).unwrap_or(gitlab_slug_to_id(f))
    let title = sidebar_titles.get(id).unwrap_or(gitlab_slug_to_title(f))
    let raw_content = @fs.read_file_to_string(wiki_dir + "/" + f + ".md") catch {
      _ => ""
    }
    let (content_without_meta, source_strings) = extract_sources_kgf(
      raw_content, spec,
    )
    let content = convert_wikilinks_to_internal(
      content_without_meta, slug_to_id, gitlab_slug_to_id, title_to_gitlab_slug,
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
/// Export @types.WikiData to GitLab Wiki format.
pub fn export_gitlab_wiki(data : @types.WikiData) -> Array[(String, String)] {
  let spec = match load_wiki_spec("gitlab-wiki") {
    Some(s) => s
    None => {
      println("Warning: gitlab-wiki KGF spec not found.")
      return []
    }
  }
  let home_name = strip_md_ext(spec.home_file)
  let result : Array[(String, String)] = []
  let id_to_title : Map[String, String] = {}
  let id_to_slug : Map[String, String] = {}
  let root_id = find_root_id(data.nav)
  for entry in data.pages {
    let id = entry.0
    let page = entry.1
    id_to_title[id] = page.title
    let slug = if id == root_id {
      home_name
    } else {
      title_to_gitlab_slug(page.title)
    }
    id_to_slug[id] = slug
  }
  for entry in data.pages {
    let id = entry.0
    let page = entry.1
    let slug = id_to_slug.get(id).unwrap_or(title_to_gitlab_slug(page.title))
    let converted = convert_internal_to_wikilinks(
      page.content,
      id_to_slug,
      id_to_title,
    )
    let sources_comment = embed_sources_comment(page.sources)
    let full_content = if sources_comment.length() > 0 {
      sources_comment + "\n" + converted
    } else {
      converted
    }
    result.push((slug + ".md", full_content))
  }
  let sidebar = render_sidebar_wikilinks(
    data.nav,
    id_to_slug,
    id_to_title,
    root_id,
    home_name,
  )
  result.push((spec.nav_file, sidebar))
  result
}

// --- GitLab-specific slug/ID helpers ---

///|
/// Convert a page title to GitLab slug.
/// "Getting Started" → "getting-started", preserves path separators.
fn title_to_gitlab_slug(title : String) -> String {
  let buf = StringBuilder::new()
  for c in title {
    if c == ' ' {
      buf.write_char('-')
    } else if c >= 'A' && c <= 'Z' {
      buf.write_char((c.to_int() + 32).unsafe_to_char())
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
/// GitLab slug to page ID (already lowercase-hyphen).
fn gitlab_slug_to_id(slug : String) -> String {
  slug
}

///|
/// Convert GitLab slug to display title.
/// "getting-started" → "Getting Started"
fn gitlab_slug_to_title(slug : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in slug {
    if c == '-' {
      buf.write_char(' ')
      capitalize_next = true
    } else if c == '/' {
      buf.write_char('/')
      capitalize_next = true
    } else if capitalize_next && c >= 'a' && c <= 'z' {
      buf.write_char((c.to_int() - 32).unsafe_to_char())
      capitalize_next = false
    } else {
      buf.write_char(c)
      capitalize_next = false
    }
  }
  buf.to_string()
}
