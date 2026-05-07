///|
/// Render scored file briefs into bounded orientation evidence rows for the
/// final agent report.
pub fn evidence_from_briefs(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientEvidence] {
  let result : Array[AgentOrientEvidence] = []
  let capped = orient_bounded_count(limit, briefs.length())
  for i = 0; i < capped; i = i + 1 {
    let brief = briefs[i]
    result.push({
      path: brief.path,
      kind: evidence_kind(brief),
      score: brief.score,
      matched_terms: brief.matched_terms,
      summary: evidence_preview(brief.summary, 220),
    })
  }
  result
}

///|
pub fn evidence_preview(text : String, max_len : Int) -> String {
  if text.length() <= max_len {
    text
  } else {
    @config_paths.substring(text, 0, max_len) + "..."
  }
}
