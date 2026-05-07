///|
/// Identify consumer and CLI surfaces that are related to the orientation task
/// but should not own domain implementation.
pub fn consumer_surfaces(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for brief in briefs {
    if !brief_is_consumer(brief) || brief.score <= 0.0 {
      continue
    }
    result.push({
      path: brief.path,
      reason: "Adapter or workflow surface related to task terms: " +
      brief.matched_terms.join(", "),
    })
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
pub fn do_not_implement_here(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for brief in briefs {
    if !role_is_cli_consumer(brief.role) || brief.score <= 0.0 {
      continue
    }
    result.push({
      path: brief.path,
      reason: "CLI files should parse options, call core packages, and render output; keep domain logic in likely owner packages.",
    })
    if result.length() >= limit {
      break
    }
  }
  result
}
