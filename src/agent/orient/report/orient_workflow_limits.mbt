///|
/// Static workflow and caution notes included in every agent orientation report.
pub fn orientation_workflow() -> Array[String] {
  [
    "Run this orientation brief before editing.", "Treat the first Likely Implementation Owners entry as the initial implementation-owner hypothesis unless follow-up evidence contradicts it.",
    "Use Knowledge Sources as context, not as implementation targets.", "Read likely owners before opening or creating CLI code.",
    "Treat consumer surfaces as callers unless evidence proves they own the domain logic.",
    "Use doc graph, grep, search, explore, and relevant audit commands to confirm the chosen owner.",
    "If your intended edit path appears under do_not_implement_here, stop and explain the conflict.",
  ]
}

///|
pub fn orientation_notes() -> Array[String] {
  [
    "This report is a preflight guardrail for coding agents, not proof of architecture.",
    "Use it as AGENTS.md, CLAUDE.md, slash-command, skill, or subagent context.",
    "External agent docs generally favor project memory, explicit subagent prompts, and task-specific reusable commands; this brief supplies the project-specific payload.",
  ]
}

///|
/// Bound report section counts according to the configured orientation limit.
pub fn orient_bounded_count(limit : Int, length : Int) -> Int {
  if limit <= 0 || limit > length {
    length
  } else {
    limit
  }
}
