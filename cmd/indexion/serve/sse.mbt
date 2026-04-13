///|
/// SSE (Server-Sent Events) streaming support for search endpoints.
///
/// SSE protocol:
///   Content-Type: text/event-stream
///   Each event: data: {json}\n\n
///
/// Event types:
///   - progress: { "type":"progress", "phase":"...", "detail":"..." }
///   - item:     { "type":"item", "data":{...} }
///   - items:    { "type":"items", "data":[...] }
///   - result:   { "type":"result", "data":{...} }  (for explore — complex object)
///   - done:     { "type":"done", "total":N }
///   - error:    { "type":"error", "message":"..." }

///|
fn sse_headers(cors : Bool) -> Map[String, String] {
  let headers : Map[String, String] = {}
  headers["content-type"] = "text/event-stream"
  headers["cache-control"] = "no-cache"
  headers["connection"] = "keep-alive"
  if cors {
    headers["access-control-allow-origin"] = "*"
    headers["access-control-allow-methods"] = "GET, POST, OPTIONS"
    headers["access-control-allow-headers"] = "Content-Type"
  }
  headers
}

///|
async fn sse_start(
  conn : @mhttp.ServerConnection,
  cors : Bool,
) -> Unit {
  conn.send_response(200, "OK", extra_headers=sse_headers(cors)) catch {
    _ => return
  }
}

///|
async fn sse_event(conn : @mhttp.ServerConnection, data : String) -> Unit {
  conn.write("data: " + data + "\n\n")
  conn.flush() catch { _ => () }
}

///|
async fn sse_progress(
  conn : @mhttp.ServerConnection,
  phase : String,
  detail : String,
) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "progress".to_json()
  obj["phase"] = phase.to_json()
  obj["detail"] = detail.to_json()
  sse_event(conn, Json::object(obj).stringify())
}

///|
async fn sse_item(conn : @mhttp.ServerConnection, item : Json) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "item".to_json()
  obj["data"] = item
  sse_event(conn, Json::object(obj).stringify())
}

///|
async fn sse_items(conn : @mhttp.ServerConnection, items : Json) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "items".to_json()
  obj["data"] = items
  sse_event(conn, Json::object(obj).stringify())
}

///|
async fn sse_result(conn : @mhttp.ServerConnection, data : Json) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "result".to_json()
  obj["data"] = data
  sse_event(conn, Json::object(obj).stringify())
}

///|
async fn sse_done(conn : @mhttp.ServerConnection, total : Int) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "done".to_json()
  obj["total"] = total.to_json()
  sse_event(conn, Json::object(obj).stringify())
  conn.end_response() catch { _ => () }
}

///|
async fn sse_error(conn : @mhttp.ServerConnection, message : String) -> Unit {
  let obj : Map[String, Json] = {}
  obj["type"] = "error".to_json()
  obj["message"] = message.to_json()
  sse_event(conn, Json::object(obj).stringify())
  conn.end_response() catch { _ => () }
}

// ─── Streaming Grep ────────────────────────────────────

///|
async fn handle_grep_stream(
  conn : @mhttp.ServerConnection,
  body_text : String,
  config : ServeConfig,
  cors : Bool,
) -> Unit {
  let json : Json = @json.parse(body_text) catch {
    _ => {
      send_json_error(conn, 400, "Invalid JSON body", cors)
      return
    }
  }
  let grep_config : @grep_cli.GrepConfig = {
    pattern: json_string(json, "pattern", ""),
    paths: {
      let p = json_string_array(json, "paths")
      if p.length() > 0 {
        for dir in p {
          if !validate_path(dir) {
            send_json_error(conn, 400, "Invalid path", cors)
            return
          }
        }
        p
      } else {
        [config.workspace_dir]
      }
    },
    includes: json_string_array(json, "includes"),
    excludes: json_string_array(json, "excludes"),
    specs_dir: config.specs_dir,
    semantic: json_string(json, "semantic", ""),
    undocumented: json_bool(json, "undocumented", false),
    context_lines: 0,
    count_only: false,
    files_only: false,
  }
  // Start SSE
  sse_start(conn, cors)
  sse_progress(conn, "searching", "Running grep...")
  match @grep_cli.run_to_json(grep_config) {
    Some(result) => {
      let parsed : Json = @json.parse(result) catch { _ => Json::array([]) }
      match parsed {
        Array(arr) => {
          // Stream items one by one for incremental display
          for item in arr {
            sse_item(conn, item)
          }
          sse_done(conn, arr.length())
        }
        _ => sse_done(conn, 0)
      }
    }
    None => sse_error(conn, "Pattern or semantic query required")
  }
}

// ─── Streaming Search ──────────────────────────────────

///|
async fn handle_search_stream(
  conn : @mhttp.ServerConnection,
  body_text : String,
  config : ServeConfig,
  cors : Bool,
) -> Unit {
  let json : Json = @json.parse(body_text) catch {
    _ => {
      send_json_error(conn, 400, "Invalid JSON body", cors)
      return
    }
  }
  let query = json_string(json, "query", "")
  if query.length() == 0 {
    send_json_error(conn, 400, "query is required", cors)
    return
  }
  let paths = json_string_array(json, "paths")
  let effective_paths = if paths.length() > 0 {
    for p in paths {
      if !validate_path(p) {
        send_json_error(conn, 400, "Invalid path", cors)
        return
      }
    }
    paths
  } else {
    [config.workspace_dir]
  }
  // Start SSE
  sse_start(conn, cors)
  sse_progress(conn, "indexing", "Building search index...")
  let search_config : @search_cli.SearchConfig = {
    query,
    paths: effective_paths,
    top_k: json_double(json, "topK", 20.0).to_int(),
    min_score: json_double(json, "minScore", 0.05),
    includes: json_string_array(json, "includes"),
    excludes: json_string_array(json, "excludes"),
    specs_dir: config.specs_dir,
    files_only: false,
    json_output: true,
    filter_str: json_string(json, "filter", ""),
    provider_name: json_string(json, "provider", "tfidf"),
    api_key_env: @embed_config.DEFAULT_API_KEY_ENV,
    model: @embed_config.DEFAULT_EMBEDDING_MODEL,
    base_url: @embed_config.DEFAULT_API_BASE_URL,
    dim: @embed_config.DEFAULT_TFIDF_DIM,
  }
  sse_progress(conn, "searching", "Querying...")
  match @search_cli.run_to_json(search_config) {
    Some(result) => {
      let parsed : Json = @json.parse(result) catch { _ => Json::array([]) }
      match parsed {
        Array(arr) => {
          for item in arr {
            sse_item(conn, item)
          }
          sse_done(conn, arr.length())
        }
        _ => sse_done(conn, 0)
      }
    }
    None => sse_error(conn, "Search failed")
  }
}

// ─── Streaming Explore ─────────────────────────────────

///|
async fn handle_explore_stream(
  conn : @mhttp.ServerConnection,
  body_text : String,
  config : ServeConfig,
  cors : Bool,
) -> Unit {
  let json : Json = @json.parse(body_text) catch {
    _ => {
      send_json_error(conn, 400, "Invalid JSON body", cors)
      return
    }
  }
  let target_dirs = json_string_array(json, "targetDirs")
  if target_dirs.length() == 0 {
    send_json_error(conn, 400, "targetDirs is required", cors)
    return
  }
  for dir in target_dirs {
    if !validate_path(dir) {
      send_json_error(conn, 400, "Invalid path", cors)
      return
    }
  }
  // Start SSE
  sse_start(conn, cors)
  sse_progress(conn, "scanning", "Collecting files...")
  let explore_config : @explore_cli.ExploreConfig = {
    target_dirs,
    format: "json",
    strategy: json_string(json, "strategy", "tfidf"),
    threshold: json_double(json, "threshold", 0.5),
    fdr: json_double(json, "fdr", 0.0),
    extensions: json_string_array(json, "extensions"),
    includes: json_string_array(json, "includes"),
    excludes: json_string_array(json, "excludes"),
    specs_dir: config.specs_dir,
  }
  sse_progress(conn, "comparing", "Analyzing similarity...")
  match @explore_cli.run_to_json(explore_config) {
    Some(result) => {
      let parsed : Json = @json.parse(result) catch { _ => Json::object({}) }
      let count = match parsed {
        Object(obj) =>
          match obj.get("pairs") {
            Some(Array(arr)) => arr.length()
            _ => 0
          }
        _ => 0
      }
      // Explore result is a complex object (files + pairs), send as single result event
      sse_result(conn, parsed)
      sse_done(conn, count)
    }
    None => sse_error(conn, "No results found")
  }
}

// ─── Streaming Digest Query ────────────────────────────

///|
async fn handle_digest_query_stream(
  conn : @mhttp.ServerConnection,
  body_text : String,
  index : @index.DigestIndex,
  digest_config : @dconfig.DigestConfig,
  cors : Bool,
) -> Unit {
  let json : Json = @json.parse(body_text) catch {
    _ => {
      send_json_error(conn, 400, "Invalid JSON body", cors)
      return
    }
  }
  let purpose = if json is { "purpose": String(p), .. } {
    p
  } else {
    send_json_error(conn, 400, "Missing 'purpose' field", cors)
    return
  }
  let top_k = if json is { "topK": Number(n, ..), .. } {
    n.to_int()
  } else {
    10
  }
  let min_score = if json is { "minScore": Number(s, ..), .. } {
    s
  } else {
    0.1
  }
  // Start SSE
  sse_start(conn, cors)
  sse_progress(conn, "querying", "Searching functions by purpose...")
  let hits = serve_query_cascade(index, digest_config, purpose, top_k)
  let mut total = 0
  for hit in hits {
    if hit.score >= min_score {
      sse_item(conn, query_hit_to_json(hit))
      total = total + 1
    }
  }
  sse_done(conn, total)
}
