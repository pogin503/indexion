///|
/// Classify orientation evidence by file role inferred from KGF metadata,
/// content type, dependency direction, and command/workflow vocabulary.
pub fn evidence_kind(brief : LocalFileBrief) -> String {
  brief.role
}

///|
pub fn brief_is_consumer(brief : LocalFileBrief) -> Bool {
  role_is_consumer(brief.role)
}

///|
pub fn map_file_is_consumer(file : AgentOrientMapFile) -> Bool {
  role_is_consumer(file.role)
}

///|
pub fn role_is_consumer(role : String) -> Bool {
  role == "consumer" || role == "cli-consumer"
}

///|
pub fn role_is_cli_consumer(role : String) -> Bool {
  role == "cli-consumer"
}

///|
pub fn role_is_documentation(role : String) -> Bool {
  role == "documentation"
}

///|
pub fn infer_file_role(
  file : @pipeline.SupportedFile,
  _structural_terms : Array[String],
  summary_terms : Array[String],
  internal_outgoing : Int,
  _internal_incoming : Int,
  external_terms? : Array[String] = [],
) -> String {
  if file.content_type == Some("document") {
    if has_workflow_surface_terms(summary_terms) {
      return "consumer"
    }
    return "documentation"
  }
  if term_list_contains_any(external_terms, ["argparse"]) {
    return "cli-consumer"
  }
  if file.content_type is Some(_) && internal_outgoing > 0 {
    return "consumer"
  }
  "implementation"
}

///|
pub fn has_workflow_surface_terms(terms : Array[String]) -> Bool {
  term_list_contains_any(terms, [
    "skill", "workflow", "agent", "command", "commands", "run", "prompt", "delegate",
    "delegation",
  ])
}

///|
pub fn term_list_contains_any(
  terms : Array[String],
  needles : Array[String],
) -> Bool {
  for needle in needles {
    if terms.contains(needle) {
      return true
    }
  }
  false
}
