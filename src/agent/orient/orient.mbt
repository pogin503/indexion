///|
priv struct LocalFileBrief {
  path : String
  summary : String
  score : Double
  matched_terms : Array[String]
}

///|
pub fn orient_agent(config : AgentOrientConfig) -> AgentOrientReport {
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dirs=config.paths,
  )
  let files = discover_files(config, registry)
  let raw_task_terms = task_tokens(config.task)
  let graph = build_graph(files, registry)
  let raw_briefs = build_file_briefs(files, graph)
  let task_terms = filter_task_terms(raw_task_terms, raw_briefs)
  let briefs = score_briefs(raw_briefs, task_terms, config.task)
  briefs.sort_by(fn(a, b) {
    let c = b.score.compare(a.score)
    if c != 0 {
      c
    } else {
      a.path.compare(b.path)
    }
  })
  let evidence = evidence_from_briefs(briefs, config.limit)
  {
    version: "agent-orient-v1",
    task: config.task,
    likely_owners: likely_owners(briefs, config.limit),
    consumer_surfaces: consumer_surfaces(briefs, config.limit),
    do_not_implement_here: do_not_implement_here(briefs, config.limit),
    required_preflight: required_preflight(briefs, config.limit),
    evidence,
    workflow: orientation_workflow(),
    notes: orientation_notes(),
  }
}

///|
fn discover_files(
  config : AgentOrientConfig,
  registry : @kgf_registry.KGFRegistry,
) -> Array[@pipeline.SupportedFile] {
  let kgf_ignore = registry.collect_ignore_patterns()
  let opts = @pipeline.DiscoverOptions::new(
    root_dir=@pipeline.root_dir_from_paths(config.paths),
    recursive=true,
    kgf_ignore~,
  )
  @pipeline.collect_supported_file_info(config.paths, opts, registry)
}

///|
fn build_graph(
  files : Array[@pipeline.SupportedFile],
  registry : @kgf_registry.KGFRegistry,
) -> @graph.CodeGraph {
  let inputs : Array[(String, String)] = []
  for file in files {
    inputs.push((file.path, file.content))
  }
  let doc_config = @build.DocConfig::new(
    inputs,
    registry.to_specs_map(),
    options=@render.RenderOptions::new(format=@render.OutputFormat::json()),
  )
  let (_, graph) = @build.build_with_graph(doc_config)
  graph
}

///|
fn build_file_briefs(
  files : Array[@pipeline.SupportedFile],
  graph : @graph.CodeGraph,
) -> Array[LocalFileBrief] {
  let symbols_by_module : Map[String, Array[String]] = {}
  for entry in graph.get_symbols() {
    let sym = entry.1
    let line = symbol_line(sym.name, sym.kind, sym.doc)
    match symbols_by_module.get(sym.module_id) {
      Some(arr) => arr.push(line)
      None => symbols_by_module.set(sym.module_id, [line])
    }
  }
  let result : Array[LocalFileBrief] = []
  for file in files {
    let summary = StringBuilder::new()
    summary.write_string(file.path)
    summary.write_string("\n")
    match symbols_by_module.get(file.path) {
      Some(lines) =>
        for line in lines {
          summary.write_string(line)
          summary.write_string("\n")
        }
      None => ()
    }
    for note in graph.get_notes("module_doc", file.path) {
      summary.write_string(note.content)
      summary.write_string("\n")
    }
    summary.write_string(file.content)
    summary.write_string("\n")
    let text = summary.to_string()
    result.push({
      path: file.path,
      summary: text,
      score: 0.0,
      matched_terms: [],
    })
  }
  result
}

///|
fn symbol_line(name : String, kind : String, doc : String?) -> String {
  match doc {
    Some(text) if text.length() > 0 => kind + " " + name + " " + text
    _ => kind + " " + name
  }
}

///|
fn orientation_score(
  task : String,
  summary : String,
  task_terms : Array[String],
  overlap : Int,
) -> Double {
  let docs = [
    @tokenizer.tokenize_for_tfidf(task),
    @tokenizer.tokenize_for_tfidf(summary),
  ]
  let batch = @tfidf.BM25Batch::from_tokens(docs)
  let lexical = if task_terms.is_empty() {
    0.0
  } else {
    overlap.to_double() / task_terms.length().to_double()
  }
  let score = lexical + batch.similarity(0, 1) * 0.1
  if score > 1.0 {
    1.0
  } else {
    score
  }
}

///|
fn task_tokens(text : String) -> Array[String] {
  let result : Array[String] = []
  for token in @tokenizer.extract_word_tokens(@tokenizer.normalize_text(text)) {
    if token.length() >= 2 && !result.contains(token) {
      result.push(token)
    }
  }
  result
}

///|
fn filter_task_terms(
  terms : Array[String],
  briefs : Array[LocalFileBrief],
) -> Array[String] {
  if briefs.is_empty() {
    return terms
  }
  let ranked : Array[(String, Int)] = []
  for term in terms {
    let mut docs = 0
    for brief in briefs {
      if task_tokens(brief.summary).contains(term) {
        docs += 1
      }
    }
    if docs > 0 {
      ranked.push((term, docs))
    }
  }
  ranked.sort_by(fn(a, b) {
    let c = a.1.compare(b.1)
    if c != 0 {
      c
    } else {
      b.0.length().compare(a.0.length())
    }
  })
  let result : Array[String] = []
  let limit = cap(16, ranked.length())
  for i = 0; i < limit; i = i + 1 {
    result.push(ranked[i].0)
  }
  result
}

///|
fn score_briefs(
  briefs : Array[LocalFileBrief],
  task_terms : Array[String],
  task : String,
) -> Array[LocalFileBrief] {
  let result : Array[LocalFileBrief] = []
  for brief in briefs {
    let matched = matched_terms(task_terms, brief.summary)
    result.push({
      path: brief.path,
      summary: brief.summary,
      score: orientation_score(
        task,
        brief.summary,
        task_terms,
        matched.length(),
      ),
      matched_terms: matched,
    })
  }
  result
}

///|
fn matched_terms(task_terms : Array[String], text : String) -> Array[String] {
  let text_terms = task_tokens(text)
  let result : Array[String] = []
  for term in task_terms {
    if text_terms.contains(term) {
      result.push(term)
    }
  }
  result
}

///|
fn evidence_from_briefs(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientEvidence] {
  let result : Array[AgentOrientEvidence] = []
  let capped = cap(limit, briefs.length())
  for i = 0; i < capped; i = i + 1 {
    let brief = briefs[i]
    result.push({
      path: brief.path,
      kind: evidence_kind(brief.path),
      score: brief.score,
      matched_terms: brief.matched_terms,
      summary: preview(brief.summary, 220),
    })
  }
  result
}

///|
fn likely_owners(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let seen : Map[String, Bool] = {}
  let result : Array[AgentOrientItem] = []
  for brief in briefs {
    if is_consumer_path(brief.path) || brief.score <= 0.0 {
      continue
    }
    let dir = owner_dir(brief.path)
    if dir.length() == 0 || seen.contains(dir) {
      continue
    }
    seen[dir] = true
    result.push({
      path: dir,
      reason: "Closest non-CLI implementation area for task terms: " +
      brief.matched_terms.join(", "),
    })
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
fn consumer_surfaces(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for brief in briefs {
    if !is_consumer_path(brief.path) || brief.score <= 0.0 {
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
fn do_not_implement_here(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  for brief in briefs {
    if !is_cli_path(brief.path) || brief.score <= 0.0 {
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

///|
fn required_preflight(
  briefs : Array[LocalFileBrief],
  limit : Int,
) -> Array[AgentOrientItem] {
  let result : Array[AgentOrientItem] = []
  let capped = cap(limit, briefs.length())
  for i = 0; i < capped; i = i + 1 {
    let brief = briefs[i]
    if brief.score <= 0.0 {
      continue
    }
    result.push({
      path: brief.path,
      reason: "Read before editing; it is part of the mechanical evidence for this task.",
    })
  }
  result
}

///|
fn orientation_workflow() -> Array[String] {
  [
    "Run this orientation brief before editing.", "Read likely owners before opening or creating CLI code.",
    "Treat consumer surfaces as callers unless evidence proves they own the domain logic.",
    "Use doc graph, grep, search, explore, and identity audit to confirm the chosen owner.",
    "If your intended edit path appears under do_not_implement_here, stop and explain the conflict.",
  ]
}

///|
fn orientation_notes() -> Array[String] {
  [
    "This report is a preflight guardrail for coding agents, not proof of architecture.",
    "Use it as AGENTS.md, CLAUDE.md, slash-command, skill, or subagent context.",
    "External agent docs generally favor project memory, explicit subagent prompts, and task-specific reusable commands; this brief supplies the project-specific payload.",
  ]
}

///|
fn evidence_kind(path : String) -> String {
  if is_cli_path(path) {
    "cli-consumer"
  } else if path.has_suffix(".md") {
    "documentation"
  } else {
    "implementation"
  }
}

///|
fn is_consumer_path(path : String) -> Bool {
  is_cli_path(path) || path.has_prefix("skills/")
}

///|
fn is_cli_path(path : String) -> Bool {
  (
    (path.has_prefix("cmd/") || path.contains("/cmd/")) &&
    path.has_suffix(".mbt")
  ) ||
  path.has_suffix("/cli.mbt")
}

///|
fn owner_dir(path : String) -> String {
  let dir = @config_paths.dirname(path)
  if dir.length() == 0 || dir == "." {
    path
  } else {
    dir
  }
}

///|
fn cap(limit : Int, length : Int) -> Int {
  if limit <= 0 || limit > length {
    length
  } else {
    limit
  }
}

///|
fn preview(text : String, max_len : Int) -> String {
  if text.length() <= max_len {
    text
  } else {
    @config_paths.substring(text, 0, max_len) + "..."
  }
}
