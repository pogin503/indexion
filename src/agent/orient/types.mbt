///|
/// Configuration for generating an agent orientation brief.
pub(all) struct AgentOrientConfig {
  task : String
  paths : Array[String]
  specs_dir : String
  cache_dir : String
  wiki_dir : String
  no_update : Bool
  limit : Int
} derive(Eq, Debug)

///|
pub fn AgentOrientConfig::default() -> AgentOrientConfig {
  {
    task: "",
    paths: ["."],
    specs_dir: "kgfs",
    cache_dir: ".indexion/cache/agent",
    wiki_dir: ".indexion/wiki",
    no_update: false,
    limit: 12,
  }
}

///|
pub(all) struct AgentOrientEvidence {
  path : String
  kind : String
  score : Double
  matched_terms : Array[String]
  summary : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct AgentOrientItem {
  path : String
  reason : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct AgentOrientQuizItem {
  question : String
  expected_answer : String
  evidence_path : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct AgentOrientMapFile {
  path : String
  source_hash : String
  owner : String
  structural_summary : String
  summary : String
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct AgentOrientMapOwner {
  path : String
  source_hash : String
  files : Array[String]
  doc_sources : Array[String]
  summary : String
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct AgentOrientMapStatus {
  total_files : Int
  total_owners : Int
  total_doc_sources : Int
  changed_files : Array[String]
  new_files : Array[String]
  deleted_files : Array[String]
  knowledge_changed : Bool
  refreshed_owners : Array[String]
  reused_owners : Array[String]
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct AgentOrientMap {
  version : String
  knowledge_hash : String
  files : Array[AgentOrientMapFile]
  owners : Array[AgentOrientMapOwner]
  status : AgentOrientMapStatus
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct AgentOrientReport {
  version : String
  task : String
  likely_owners : Array[AgentOrientItem]
  knowledge_sources : Array[AgentOrientItem]
  consumer_surfaces : Array[AgentOrientItem]
  do_not_implement_here : Array[AgentOrientItem]
  required_preflight : Array[AgentOrientItem]
  readiness_quiz : Array[AgentOrientQuizItem]
  map_status : AgentOrientMapStatus
  evidence : Array[AgentOrientEvidence]
  workflow : Array[String]
  notes : Array[String]
} derive(Eq, Debug, ToJson)
