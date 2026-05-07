///|
type AgentOrientConfig = @types.AgentOrientConfig

///|
type AgentOrientEvidence = @types.AgentOrientEvidence

///|
type AgentOrientItem = @types.AgentOrientItem

///|
type AgentOrientMap = @types.AgentOrientMap

///|
type AgentOrientMapFile = @types.AgentOrientMapFile

///|
type AgentOrientMapOwner = @types.AgentOrientMapOwner

///|
type AgentOrientQuizItem = @types.AgentOrientQuizItem

///|
type AgentOrientReport = @types.AgentOrientReport

///|
type LocalFileBrief = @types.LocalFileBrief

///|
fn filter_task_terms(
  terms : Array[String],
  briefs : Array[LocalFileBrief],
) -> Array[String] {
  @matching.filter_task_terms(terms, briefs)
}

///|
fn owner_task_terms_from_map(
  raw_terms : Array[String],
  orient_map : AgentOrientMap,
) -> Array[String] {
  @matching.owner_task_terms_from_map(raw_terms, orient_map)
}

///|
fn score_briefs(
  briefs : Array[LocalFileBrief],
  task_terms : Array[String],
  task : String,
) -> Array[LocalFileBrief] {
  @matching.score_briefs(briefs, task_terms, task)
}

///|
fn brief_is_consumer(brief : LocalFileBrief) -> Bool {
  @matching.brief_is_consumer(brief)
}

///|
fn role_is_cli_consumer(role : String) -> Bool {
  @matching.role_is_cli_consumer(role)
}

///|
fn map_file_is_consumer(file : AgentOrientMapFile) -> Bool {
  @matching.map_file_is_consumer(file)
}

///|
fn evidence_kind(brief : LocalFileBrief) -> String {
  @matching.evidence_kind(brief)
}

///|
fn source_matches_owner(source : String, owner : String) -> Bool {
  @map.source_matches_owner(source, owner)
}

///|
fn likely_owners(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
  limit : Int,
) -> Array[AgentOrientItem] {
  @owner.likely_owners(orient_map, task_terms, task, limit)
}

///|
fn likely_knowledge_sources(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
  limit : Int,
) -> Array[AgentOrientItem] {
  @owner.likely_knowledge_sources(orient_map, task_terms, task, limit)
}

///|
fn new_local_file_brief(
  path : String,
  source_hash : String,
  structural_summary : String,
  summary : String,
  role? : String = "implementation",
  structural_terms? : Array[String] = [],
  summary_terms? : Array[String] = [],
) -> LocalFileBrief {
  @source.new_local_file_brief(
    path,
    source_hash,
    structural_summary,
    summary,
    role~,
    structural_terms~,
    summary_terms~,
  )
}

///|
/// Compose the final agent orientation report from scored file briefs, likely
/// owners, knowledge sources, consumer surfaces, preflight, and workflow notes.
pub fn orient_report_from_map(
  config : AgentOrientConfig,
  raw_task_terms : Array[String],
  raw_briefs : Array[LocalFileBrief],
  orient_map : AgentOrientMap,
) -> AgentOrientReport {
  let file_task_terms = filter_task_terms(raw_task_terms, raw_briefs)
  let owner_task_terms = owner_task_terms_from_map(raw_task_terms, orient_map)
  let briefs = score_briefs(raw_briefs, file_task_terms, config.task)
  briefs.sort_by(fn(a, b) {
    let c = b.score.compare(a.score)
    if c != 0 {
      c
    } else {
      a.path.compare(b.path)
    }
  })
  let evidence = evidence_from_briefs(briefs, config.limit)
  let owners = likely_owners(
    orient_map,
    if owner_task_terms.is_empty() {
      file_task_terms
    } else {
      owner_task_terms
    },
    config.task,
    config.limit,
  )
  let knowledge_sources = likely_knowledge_sources(
    orient_map,
    if owner_task_terms.is_empty() {
      file_task_terms
    } else {
      owner_task_terms
    },
    config.task,
    config.limit,
  )
  let consumers = consumer_surfaces(briefs, config.limit)
  let forbidden = do_not_implement_here(briefs, config.limit)
  let preflight = required_preflight(orient_map, owners, briefs, config.limit)
  {
    version: "agent-orient-v1",
    task: config.task,
    likely_owners: owners,
    knowledge_sources,
    consumer_surfaces: consumers,
    do_not_implement_here: forbidden,
    required_preflight: preflight,
    readiness_quiz: readiness_quiz(
      owners, knowledge_sources, consumers, forbidden, preflight,
    ),
    map_status: orient_map.status,
    evidence,
    workflow: orientation_workflow(),
    notes: orientation_notes(),
  }
}

///|
pub fn briefs_from_orient_map(map : AgentOrientMap) -> Array[LocalFileBrief] {
  let briefs : Array[LocalFileBrief] = []
  for file in map.files {
    briefs.push(
      new_local_file_brief(
        file.path,
        file.source_hash,
        file.structural_summary,
        file.summary,
        role=file.role,
      ),
    )
  }
  briefs
}
