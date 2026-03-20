///|
/// doc.json-based README generation using PlanDocument IR.

///|
/// Run README generation using doc.json configuration.
pub fn run_with_doc_config(
  config_path : String,
  cli_config : ReadmeConfig,
) -> Unit {
  log_progress("[1/3] Loading doc.json...")
  let doc_config = match @doc_config.load_doc_config(config_path) {
    Some(cfg) => cfg
    None => {
      println("Error: Could not load config file: " + config_path)
      return
    }
  }
  log_progress(
    "      Loaded " +
    doc_config.packages.length().to_string() +
    " package entries",
  )
  // Determine output file
  let output_path = match cli_config.output {
    Some(path) => path
    None => doc_config.root.output
  }
  log_progress("[2/3] Building document IR...")
  let doc = build_root_document(doc_config)
  let result = @plan_render.render_markdown(doc)
  log_progress("[3/3] Writing output...")
  write_output(result, Some(output_path), false)
  println("Written to: " + output_path)
}

///|
/// Build a PlanDocument from doc.json configuration.
/// Static files, TOC headings, and package entries are all represented as IR sections.
fn build_root_document(
  config : @doc_config.DocConfig,
) -> @plan_types.PlanDocument {
  // First pass: extract title from first static file's # heading
  let title = extract_document_title(config)
  let doc = @plan_types.PlanDocument::new(title)
  // Second pass: build sections
  let mut pending_toc_title : String = ""
  let mut has_pending_toc = false
  let mut title_extracted = false
  for section in config.root.sections {
    match section {
      @doc_config.DocRootSection::Static(file_path) => {
        flush_pending_toc(doc, pending_toc_title, has_pending_toc, [])
        has_pending_toc = false
        let content = @fs.read_file_to_string(file_path) catch {
          _ => {
            println("Warning: Could not read file: " + file_path)
            continue
          }
        }
        let parsed = parse_markdown_to_sections(content)
        for s in parsed {
          // Skip the first heading that became the document title
          if not(title_extracted) && s.heading == title && s.heading.length() > 0 {
            title_extracted = true
            // Add children of the title section as top-level sections
            match s.content {
              @plan_types.SectionContent::Nested(children) =>
                for child in children {
                  doc.add_section(child)
                }
              _ =>
                if get_section_text(s.content).length() > 0 {
                  doc.add_section(
                    @plan_types.PlanSection::new("", "", s.content),
                  )
                }
            }
          } else {
            doc.add_section(s)
          }
        }
      }
      @doc_config.DocRootSection::Toc(title) => {
        flush_pending_toc(doc, pending_toc_title, has_pending_toc, [])
        pending_toc_title = title
        has_pending_toc = true
      }
      @doc_config.DocRootSection::Packages(filter) => {
        let children : Array[@plan_types.PlanSection] = []
        let filtered = filter_packages(config.packages, filter)
        for entry in filtered {
          if not(entry.include_in_root) {
            continue
          }
          match build_package_section(entry) {
            Some(s) => children.push(s)
            None => ()
          }
        }
        if has_pending_toc {
          flush_pending_toc(doc, pending_toc_title, true, children)
          has_pending_toc = false
        } else {
          for child in children {
            doc.add_section(child)
          }
        }
      }
    }
  }
  flush_pending_toc(doc, pending_toc_title, has_pending_toc, [])
  doc
}

///|
/// Extract document title from first static file's # heading.
fn extract_document_title(config : @doc_config.DocConfig) -> String {
  for section in config.root.sections {
    match section {
      @doc_config.DocRootSection::Static(file_path) => {
        let content = @fs.read_file_to_string(file_path) catch { _ => continue }
        let parsed = parse_markdown_to_sections(content)
        for s in parsed {
          if s.heading.length() > 0 {
            return s.heading
          }
        }
      }
      _ => ()
    }
  }
  "README"
}

///|
/// Flush a pending TOC section with optional package children.
fn flush_pending_toc(
  doc : @plan_types.PlanDocument,
  title : String,
  has_pending : Bool,
  children : Array[@plan_types.PlanSection],
) -> Unit {
  if not(has_pending) {
    return
  }
  if children.length() > 0 {
    doc.add_section(
      @plan_types.PlanSection::new(
        "toc", title, @plan_types.SectionContent::nested(children),
      ),
    )
  } else {
    doc.add_section(
      @plan_types.PlanSection::new(
        "toc", title, @plan_types.SectionContent::text(""),
      ),
    )
  }
}

///|
/// Extract children from the first heading section.
/// Package READMEs have `# Title` as root; we want its children for filtering.
fn extract_children_sections(
  sections : Array[@plan_types.PlanSection],
) -> Array[@plan_types.PlanSection] {
  // If there's a single top-level heading with nested children, return those children
  if sections.length() == 1 {
    match sections[0].content {
      @plan_types.SectionContent::Nested(children) => return children
      _ => ()
    }
  }
  // If first section is a heading and has nested children, include anonymous pre-heading
  // text as "overview" and the children
  for section in sections {
    if section.heading.length() > 0 {
      match section.content {
        @plan_types.SectionContent::Nested(children) => return children
        _ => ()
      }
    }
  }
  sections
}

///|
/// Extract text content from SectionContent (for simple sections).
fn get_section_text(content : @plan_types.SectionContent) -> String {
  match content {
    @plan_types.SectionContent::Text(s) => s
    _ => ""
  }
}

///|
/// Build a PlanSection for a package entry from its README.md.
/// Returns None if the README cannot be read.
fn build_package_section(
  entry : @doc_config.DocPackageEntry,
) -> @plan_types.PlanSection? {
  let readme_path = entry.path + "/README.md"
  let readme_content = @fs.read_file_to_string(readme_path) catch {
    _ => return None
  }
  // Parse README into IR sections
  let all_sections = parse_markdown_to_sections(readme_content)
  // Package READMEs typically have a # title with children.
  // Extract children from the first heading section for filtering.
  let sections_to_filter = extract_children_sections(all_sections)
  // Filter by requested sections (e.g., ["overview", "usage"])
  let filtered = filter_parsed_sections(sections_to_filter, entry.sections)
  // Add documentation link as last child
  let children : Array[@plan_types.PlanSection] = []
  for s in filtered {
    children.push(s)
  }
  children.push(
    @plan_types.PlanSection::new(
      "link",
      "",
      @plan_types.SectionContent::text(
        "\n[Full documentation](" + readme_path + ")",
      ),
    ),
  )
  Some(
    @plan_types.PlanSection::new(
      entry.title,
      "`indexion " + entry.title + "`",
      @plan_types.SectionContent::nested(children),
    ),
  )
}

///|
/// Filter packages by glob pattern.
fn filter_packages(
  packages : Array[@doc_config.DocPackageEntry],
  filter : String,
) -> Array[@doc_config.DocPackageEntry] {
  if filter == "**" || filter == "*" {
    return packages
  }
  let result : Array[@doc_config.DocPackageEntry] = []
  for entry in packages {
    if glob_match_path(filter, entry.path) {
      result.push(entry)
    }
  }
  result
}

///|
/// Simple glob matching for paths.
fn glob_match_path(pattern : String, path : String) -> Bool {
  // Handle "cmd/**" pattern
  if pattern.has_suffix("/**") {
    let prefix = substring_config(pattern, 0, pattern.length() - 3)
    return path.has_prefix(prefix)
  }
  // Handle "cmd/*" pattern
  if pattern.has_suffix("/*") {
    let prefix = substring_config(pattern, 0, pattern.length() - 2)
    if not(path.has_prefix(prefix)) {
      return false
    }
    // Check that there's no additional / after the prefix
    let rest = substring_config(path, prefix.length() + 1, path.length())
    return not(rest.contains("/"))
  }
  // Exact match
  pattern == path
}

///|
fn substring_config(s : String, start : Int, end : Int) -> String {
  let chars = s.to_array()
  if start >= end || start >= chars.length() {
    return ""
  }
  let actual_end = if end > chars.length() { chars.length() } else { end }
  let result : Array[Char] = []
  for i = start; i < actual_end; i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result)
}
