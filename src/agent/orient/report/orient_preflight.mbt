///|
/// Build required preflight evidence paths for agents before implementation.
pub fn required_preflight(
  orient_map : AgentOrientMap,
  owners : Array[AgentOrientItem],
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for item in owner_preflight(orient_map, owners, limit) {
    push_preflight_item(result, item)
    if result.length() >= limit {
      return result
    }
  }
  let capped = orient_bounded_count(limit, briefs.length())
  for i = 0; i < capped; i = i + 1 {
    let brief = briefs[i]
    if brief.score <= 0.0 {
      continue
    }
    push_preflight_item(result, {
      path: brief.path,
      reason: "Read before editing; it is part of the mechanical evidence for this task.",
    })
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
pub fn owner_preflight(
  orient_map : AgentOrientMap,
  owners : Array[AgentOrientItem],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for owner_item in owners {
    let owner = find_orient_owner(orient_map, owner_item.path)
    if owner is None {
      continue
    }
    let owner = owner.unwrap()
    for path in preferred_owner_evidence_paths(owner, orient_map) {
      result.push({
        path,
        reason: "Read first to confirm the likely owner before editing consumers or CLI adapters.",
      })
      if result.length() >= limit {
        return result
      }
    }
  }
  result
}

///|
pub fn find_orient_owner(
  orient_map : AgentOrientMap,
  path : String,
) -> AgentOrientMapOwner? {
  for owner in orient_map.owners {
    if owner.path == path {
      return Some(owner)
    }
  }
  None
}

///|
pub fn preferred_owner_evidence_paths(
  owner : AgentOrientMapOwner,
  orient_map : AgentOrientMap,
) -> Array[String] {
  let result : Array[String] = []
  for path in owner.doc_sources {
    if source_matches_owner(path, owner.path) && !result.contains(path) {
      result.push(path)
    }
  }
  for path in owner.files {
    if !orient_map_file_is_consumer(orient_map, path) && !result.contains(path) {
      result.push(path)
    }
  }
  result
}

///|
pub fn orient_map_file_is_consumer(
  orient_map : AgentOrientMap,
  path : String,
) -> Bool {
  for file in orient_map.files {
    if file.path == path {
      return map_file_is_consumer(file)
    }
  }
  false
}

///|
pub fn push_preflight_item(
  result : Array[AgentOrientItem],
  item : AgentOrientItem,
) -> Unit {
  for existing in result {
    if existing.path == item.path {
      return
    }
  }
  result.push(item)
}
