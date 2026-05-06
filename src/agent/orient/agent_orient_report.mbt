///|
/// Scored evidence row rendered in an agent orientation brief.
pub(all) struct AgentOrientEvidence {
  path : String
  kind : String
  score : Double
  matched_terms : Array[String]
  summary : String
} derive(Eq, Debug, ToJson)

///|
/// Path and reason item rendered in an agent orientation brief section.
pub(all) struct AgentOrientItem {
  path : String
  reason : String
} derive(Eq, Debug, ToJson)

///|
/// Readiness quiz item used to verify that a zero-knowledge agent understood the brief.
pub(all) struct AgentOrientQuizItem {
  question : String
  expected_answer : String
  evidence_path : String
} derive(Eq, Debug, ToJson)

///|
/// Agent orientation brief separating implementation owners from knowledge sources.
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
