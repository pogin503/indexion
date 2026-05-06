///|
/// Configuration for generating an agent orientation brief.
pub(all) struct AgentOrientConfig {
  task : String
  paths : Array[String]
  specs_dir : String
  limit : Int
} derive(Eq, Debug)

///|
pub fn AgentOrientConfig::default() -> AgentOrientConfig {
  { task: "", paths: ["."], specs_dir: "kgfs", limit: 12 }
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
pub(all) struct AgentOrientReport {
  version : String
  task : String
  likely_owners : Array[AgentOrientItem]
  consumer_surfaces : Array[AgentOrientItem]
  do_not_implement_here : Array[AgentOrientItem]
  required_preflight : Array[AgentOrientItem]
  evidence : Array[AgentOrientEvidence]
  workflow : Array[String]
  notes : Array[String]
} derive(Eq, Debug, ToJson)
