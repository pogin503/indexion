///|
/// # Wiki Serving
///
/// Loads wiki pages from .indexion/wiki/ directory.
/// Builds a search index using the same embedding provider as digest.

///|
async fn load_wiki_pages(
  config : ServeConfig,
  provider : @dconfig.EmbeddingProvider,
) -> (@wiki_types.WikiData, @wiki_search.WikiSearchIndex?) {
  let wiki_dir = match
    @config.resolve_project_indexion_dir(config.workspace_dir, "wiki") {
    Some(dir) => dir
    None => {
      @digest_cli.log_progress("Wiki: no project root found. Skipping wiki.")
      return (empty_wiki(), None)
    }
  }
  let registry = @kgf_features.load_registry(
    specs_dir=config.specs_dir,
    target_dir=config.workspace_dir,
  )
  match @wiki_interop.load_wiki_auto(wiki_dir, registry~) {
    Some(data) => {
      @digest_cli.log_progress(
        "Wiki: " + data.pages.length().to_string() + " pages loaded.",
      )
      let search = @wiki_search.build_search_index(
        data.pages,
        provider,
        registry~,
      ) catch {
        _ => {
          @digest_cli.log_progress(
            "Wiki search: embedding failed, using TF-IDF fallback.",
          )
          @wiki_search.build_search_index(
            data.pages,
            @dconfig.TfIdf(256),
            registry~,
          ) catch {
            _ => {
              @digest_cli.log_progress("Wiki search: failed to build index.")
              return (data, None)
            }
          }
        }
      }
      @digest_cli.log_progress(
        "Wiki search: " +
        search.sections.length().to_string() +
        " sections indexed.",
      )
      (data, Some(search))
    }
    None => {
      @digest_cli.log_progress(
        "Wiki: no .indexion/wiki/ found. Run `indexion plan wiki` to generate.",
      )
      (empty_wiki(), None)
    }
  }
}

///|
async fn handle_wiki_search(
  conn : @mhttp.ServerConnection,
  body_text : String,
  search_index : @wiki_search.WikiSearchIndex?,
  cors : Bool,
) -> Unit {
  match search_index {
    None => {
      send_json_error(conn, 404, "Wiki search index not available", cors)
      return
    }
    Some(idx) => {
      let json : Json = @json.parse(body_text) catch {
        _ => {
          send_json_error(conn, 400, "Invalid JSON body", cors)
          return
        }
      }
      let query = if json is { "query": String(q), .. } {
        q
      } else {
        send_json_error(conn, 400, "Missing 'query' field", cors)
        return
      }
      let top_k = if json is { "topK": Number(n, ..), .. } {
        n.to_int()
      } else {
        10
      }
      let hits = idx.search(query, top_k~)
      let results : Array[Json] = []
      for hit in hits {
        results.push(hit.to_json())
      }
      send_json_ok(conn, Json::array(results).stringify(), cors)
    }
  }
}

///|
fn empty_wiki() -> @wiki_types.WikiData {
  let placeholder = @wiki_types.WikiPage::new(
    id="overview",
    title="Wiki Not Generated",
    content="# Wiki Not Generated\n\nRun `indexion plan wiki` to generate a wiki structure, then have an agent write the pages.\n",
  )
  let pages : Map[String, @wiki_types.WikiPage] = {}
  pages["overview"] = placeholder
  let nav = @wiki_types.WikiNav::new(pages=[
    @wiki_types.WikiNavItem::new(id="overview", title="Overview"),
  ])
  @wiki_types.WikiData::new(nav~, pages~)
}
