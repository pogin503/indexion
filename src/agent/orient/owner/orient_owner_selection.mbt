///|
/// Select likely implementation owners and documentation-only knowledge sources
/// from scored owner profiles.
pub fn likely_owners(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
  limit : Int,
) -> Array[AgentOrientItem] {
  let owner_briefs = score_owner_briefs(orient_map, task_terms, task)
  let result : Array[AgentOrientItem] = []
  let mut rank = 0
  for brief in owner_briefs {
    if brief.score <= 0.0 {
      continue
    }
    if !owner_has_implementation(orient_map, brief.path) {
      continue
    }
    let reason = if rank == 0 {
      "Initial implementation-owner hypothesis; highest-scored implementation profile for task terms: "
    } else {
      "Alternate implementation owner candidate for task terms: "
    }
    result.push({
      path: brief.path,
      reason: reason + brief.matched_terms.join(", "),
    })
    rank += 1
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
pub fn likely_knowledge_sources(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
  limit : Int,
) -> Array[AgentOrientItem] {
  let owner_briefs = score_owner_briefs(orient_map, task_terms, task)
  let result : Array[AgentOrientItem] = []
  for brief in owner_briefs {
    if brief.score <= 0.0 || owner_has_implementation(orient_map, brief.path) {
      continue
    }
    result.push({
      path: brief.path,
      reason: "Knowledge source matching task terms; use as context, not as an implementation target: " +
      brief.matched_terms.join(", "),
    })
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
pub fn owner_has_implementation(
  orient_map : AgentOrientMap,
  path : String,
) -> Bool {
  match find_orient_owner(orient_map, path) {
    None => false
    Some(owner) => {
      for file in owner.files {
        if !owner_file_is_documentation(orient_map, file) {
          return true
        }
      }
      false
    }
  }
}

///|
fn find_orient_owner(
  orient_map : AgentOrientMap,
  path : String,
) -> @types.AgentOrientMapOwner? {
  for owner in orient_map.owners {
    if owner.path == path {
      return Some(owner)
    }
  }
  None
}

///|
pub fn owner_file_is_documentation(
  orient_map : AgentOrientMap,
  path : String,
) -> Bool {
  for file in orient_map.files {
    if file.path == path {
      return role_is_documentation(file.role) ||
        is_documentation_path(file.path)
    }
  }
  is_documentation_path(path)
}
