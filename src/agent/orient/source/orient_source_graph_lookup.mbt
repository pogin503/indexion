///|
pub fn graph_endpoint_file(
  endpoint : String,
  graph : @graph.CodeGraph,
) -> String? {
  match graph.get_module(endpoint) {
    Some(mod_node) =>
      match mod_node.file {
        Some(path) => return Some(path)
        None => ()
      }
    None => ()
  }
  if graph.get_modules().contains(endpoint) {
    Some(endpoint)
  } else {
    None
  }
}

///|
pub fn internal_outgoing_count(
  counts : Map[String, (Int, Int)],
  path : String,
) -> Int {
  counts.get(path).unwrap_or((0, 0)).0
}

///|
pub fn internal_incoming_count(
  counts : Map[String, (Int, Int)],
  path : String,
) -> Int {
  counts.get(path).unwrap_or((0, 0)).1
}

///|
pub fn cached_file_for(
  path : String,
  source_hash : String,
  cached_map : AgentOrientMap?,
) -> AgentOrientMapFile? {
  match cached_map {
    None => None
    Some(map) => {
      for file in map.files {
        if file.path == path && file.source_hash == source_hash {
          return Some(file)
        }
      }
      None
    }
  }
}
