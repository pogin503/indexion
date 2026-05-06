///|
/// Source file entry stored in the agent orientation map.
pub(all) struct AgentOrientMapFile {
  path : String
  source_hash : String
  owner : String
  structural_summary : String
  summary : String
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
/// Implementation owner profile stored in the agent orientation map.
pub(all) struct AgentOrientMapOwner {
  path : String
  source_hash : String
  files : Array[String]
  doc_sources : Array[String]
  summary : String
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
/// Incremental refresh status for the agent orientation map.
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
/// Cached agent orientation map used for immediate owner and knowledge recall.
pub(all) struct AgentOrientMap {
  version : String
  knowledge_hash : String
  files : Array[AgentOrientMapFile]
  owners : Array[AgentOrientMapOwner]
  status : AgentOrientMapStatus
} derive(Eq, Debug, ToJson, @json.FromJson)
