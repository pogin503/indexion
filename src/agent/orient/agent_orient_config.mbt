///|
/// Configuration for generating an agent orientation brief and its cached map.
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
