///|
/// # Wiki Search Index
///
/// Builds a search index over wiki page sections using the shared
/// SearchEngine from `src/search/`. Sections are split at h2 boundaries.

///|
/// A searchable section extracted from a wiki page.
pub struct WikiSection {
  /// Unique ID: "{page_id}#{anchor}"
  id : String
  /// Section heading text
  title : String
  /// Full text content of the section
  content : String
  /// Page ID this section belongs to
  page_id : String
  /// Heading level (2, 3, 4), or 1 for page-level
  level : Int
} derive(ToJson, @json.FromJson)

///|
/// A search hit from the wiki index.
pub struct WikiSearchHit {
  section : WikiSection
  score : Double
} derive(ToJson)

///|
/// Wiki search index — wraps SearchEngine with wiki-specific metadata.
pub struct WikiSearchIndex {
  engine : @search_engine.SearchEngine
  sections : Map[String, WikiSection]
}

///|
/// Build a search index from wiki pages.
/// Uses the shared SearchEngine with the specified EmbeddingProvider.
pub async fn build_search_index(
  pages : Map[String, @types.WikiPage],
  provider : @embed_config.EmbeddingProvider,
  registry? : @kgf_registry.KGFRegistry? = None,
) -> WikiSearchIndex raise @embed.EmbedError {
  let sections : Map[String, WikiSection] = {}
  let documents : Array[@search_engine.SearchDocument] = []
  for entry in pages {
    let page_id = entry.0
    let page = entry.1
    let page_file = if page.file.length() > 0 { page.file } else { page_id }
    for
      s in extract_sections(
        page_id,
        page.title,
        page.content,
        path=page_file,
        registry~,
      ) {
      sections[s.id] = s
      let kind_str = if s.level == 1 { "page" } else { "section" }
      let doc_attrs : Map[String, String] = {}
      doc_attrs["node_type"] = @kgf_features.node_type_document
      doc_attrs["node_kind"] = kind_str
      doc_attrs["parent"] = page_id
      documents.push({
        id: s.id,
        text: s.title + " " + s.content,
        title: s.title,
        source: page_id,
        line: 0,
        kind: kind_str,
        attrs: doc_attrs,
      })
    }
  }
  let engine = @search_engine.SearchEngine::build(documents, provider~)
  { engine, sections }
}

///|
/// Search the wiki index by natural language query.
pub async fn WikiSearchIndex::search(
  self : WikiSearchIndex,
  query : String,
  top_k? : Int = 10,
  min_score? : Double = 0.05,
) -> Array[WikiSearchHit] {
  let hits = self.engine.search(query, top_k~, min_score~)
  let results : Array[WikiSearchHit] = []
  for hit in hits {
    match self.sections.get(hit.document.id) {
      Some(section) =>
        results.push(WikiSearchHit::{ section, score: hit.score })
      None => ()
    }
  }
  results
}

///|
/// Persist the search index to wiki_dir (vectors.db + search-sections.json).
pub fn WikiSearchIndex::save(self : WikiSearchIndex, wiki_dir : String) -> Unit {
  save(self, wiki_dir)
}

///|
/// Load a persisted search index from wiki_dir.
/// Returns None if the index does not exist or cannot be loaded.
pub fn WikiSearchIndex::load(wiki_dir : String) -> WikiSearchIndex? {
  load(wiki_dir)
}

// --- Section extraction ---

///|
/// Extract sections from page content using KGF tokenization.
/// Falls back to loading KGF registry from default kgfs/ directory.
pub fn extract_sections(
  page_id : String,
  page_title : String,
  content : String,
  path? : String = "",
  registry? : @kgf_registry.KGFRegistry? = None,
) -> Array[WikiSection] {
  let effective_path = if path.length() > 0 { path } else { page_id }
  let effective_reg = match registry {
    Some(r) => r
    None =>
      return [
        WikiSection::{
          id: page_id,
          title: page_title,
          content,
          page_id,
          level: 1,
        },
      ]
  }
  let spec = match effective_reg.detect_from_path(effective_path) {
    Some(lang) => effective_reg.get_spec(lang)
    None => None
  }
  let tokens = @kgf_features.tokenize_source(content, effective_path, registry)
  match tokens {
    Some(toks) =>
      extract_sections_from_document(
        @doc_structure.extract_document_sections(toks, content, spec~),
        page_id,
        page_title,
      )
    None =>
      // If no KGF spec matches, return full page as single section
      [
        WikiSection::{
          id: page_id,
          title: page_title,
          content,
          page_id,
          level: 1,
        },
      ]
  }
}

///|
/// Extract sections from generic document sections.
fn extract_sections_from_document(
  raw_sections : Array[@doc_structure.DocumentSection],
  page_id : String,
  page_title : String,
) -> Array[WikiSection] {
  let sections : Array[WikiSection] = []
  for idx, section in raw_sections {
    let level = section.level.unwrap_or(if idx == 0 { 1 } else { 2 })
    let id = if idx == 0 {
      page_id
    } else {
      page_id +
      "#" +
      @common.make_anchor(section.title) +
      "-" +
      (idx + 1).to_string()
    }
    sections.push(WikiSection::{
      id,
      title: if idx == 0 {
        page_title
      } else {
        section.title
      },
      content: section.content,
      page_id,
      level,
    })
  }
  sections
}
