///|
priv struct LocalFileBrief {
  path : String
  source_hash : String
  structural_summary : String
  summary : String
  structural_terms : Array[String]
  summary_terms : Array[String]
  score : Double
  matched_terms : Array[String]
}

///|
priv struct LocalOwnerBrief {
  path : String
  score : Double
  matched_terms : Array[String]
}

///|
priv struct LocalTermRank {
  term : String
  owner_docs : Int
  consumer_docs : Int
  all_docs : Int
}

///|
priv struct LocalDocSource {
  path : String
  owner : String
  source_hash : String
  content : String
}

///|
priv struct LocalWikiPage {
  id : String
  title : String
  file : String
  sources : Array[String]
} derive(@json.FromJson)

///|
priv struct LocalWikiManifest {
  pages : Array[LocalWikiPage]
} derive(@json.FromJson)

///|
pub fn orient_agent(config : AgentOrientConfig) -> AgentOrientReport {
  let cached_map = load_cached_orient_map(config)
  let raw_task_terms = task_tokens(config.task)
  if config.no_update {
    match cached_map {
      Some(map) => {
        let orient_map = { ..map, status: map_status_for_cached(map) }
        return orient_report_from_map(
          config,
          raw_task_terms,
          briefs_from_orient_map(orient_map),
          orient_map,
        )
      }
      None => ()
    }
  }
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dirs=config.paths,
  )
  let files = discover_files(config, registry)
  let graph = build_graph(files, registry)
  let raw_briefs = build_file_briefs(files, graph, cached_map)
  let orient_map = build_or_update_orient_map(config, raw_briefs, cached_map)
  if !config.no_update {
    save_orient_map(config, orient_map)
  }
  orient_report_from_map(config, raw_task_terms, raw_briefs, orient_map)
}

///|
fn orient_report_from_map(
  config : AgentOrientConfig,
  raw_task_terms : Array[String],
  raw_briefs : Array[LocalFileBrief],
  orient_map : AgentOrientMap,
) -> AgentOrientReport {
  let file_task_terms = filter_task_terms(raw_task_terms, raw_briefs)
  let owner_task_terms = owner_task_terms_for_task(
    config.task,
    raw_task_terms,
    orient_map,
  )
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
  let consumers = consumer_surfaces(briefs, config.limit)
  let forbidden = do_not_implement_here(briefs, config.limit)
  let preflight = required_preflight(briefs, config.limit)
  {
    version: "agent-orient-v1",
    task: config.task,
    likely_owners: owners,
    consumer_surfaces: consumers,
    do_not_implement_here: forbidden,
    required_preflight: preflight,
    readiness_quiz: readiness_quiz(owners, consumers, forbidden, preflight),
    map_status: orient_map.status,
    evidence,
    workflow: orientation_workflow(),
    notes: orientation_notes(),
  }
}

///|
fn briefs_from_orient_map(map : AgentOrientMap) -> Array[LocalFileBrief] {
  let briefs : Array[LocalFileBrief] = []
  for file in map.files {
    briefs.push(
      new_local_file_brief(
        file.path,
        file.source_hash,
        file.structural_summary,
        file.summary,
      ),
    )
  }
  briefs
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
  cached_map : AgentOrientMap?,
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
    let source_hash = @cas_hash.compute_hash(file.content).to_string()
    match cached_file_for(file.path, source_hash, cached_map) {
      Some(cached) => {
        result.push(
          new_local_file_brief(
            cached.path,
            cached.source_hash,
            cached.structural_summary,
            cached.summary,
          ),
        )
        continue
      }
      None => ()
    }
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
    let structural = structural_summary(file, graph, symbols_by_module)
    result.push(new_local_file_brief(file.path, source_hash, structural, text))
  }
  result
}

///|
fn new_local_file_brief(
  path : String,
  source_hash : String,
  structural_summary : String,
  summary : String,
) -> LocalFileBrief {
  {
    path,
    source_hash,
    structural_summary,
    summary,
    structural_terms: task_tokens(structural_summary),
    summary_terms: task_tokens(summary),
    score: 0.0,
    matched_terms: [],
  }
}

///|
fn cached_file_for(
  path : String,
  source_hash : String,
  cached_map : AgentOrientMap?,
) -> AgentOrientMapFile? {
  match cached_map {
    None => None
    Some(map) => {
      for file in map.files {
        if file.path == path && file.source_hash == source_hash {
          return Some(file)
        }
      }
      None
    }
  }
}

///|
fn structural_summary(
  file : @pipeline.SupportedFile,
  graph : @graph.CodeGraph,
  symbols_by_module : Map[String, Array[String]],
) -> String {
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
  summary.to_string()
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
    push_orient_token(result, token)
    for part in split_orient_token(token) {
      push_orient_token(result, part)
    }
  }
  result
}

///|
fn push_orient_token(result : Array[String], token : String) -> Unit {
  let canonical = canonical_orient_token(token)
  if canonical.length() >= 2 && !result.contains(canonical) {
    result.push(canonical)
  }
}

///|
fn split_orient_token(token : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder::new()
  for ch in token {
    if ch == '-' || ch == '_' {
      let part = buf.to_string()
      if part.length() > 0 {
        parts.push(part)
      }
      buf.reset()
    } else {
      buf.write_char(ch)
    }
  }
  let last = buf.to_string()
  if last.length() > 0 {
    parts.push(last)
  }
  parts
}

///|
fn canonical_orient_token(token : String) -> String {
  if token.length() > 5 && token.has_suffix("ies") {
    return @config_paths.substring(token, 0, token.length() - 3) + "y"
  }
  if token.length() > 5 &&
    (
      token.has_suffix("sses") ||
      token.has_suffix("ches") ||
      token.has_suffix("shes") ||
      token.has_suffix("xes") ||
      token.has_suffix("zes")
    ) {
    return @config_paths.substring(token, 0, token.length() - 2)
  }
  if token.length() > 4 && token.has_suffix("s") && !token.has_suffix("ss") {
    return @config_paths.substring(token, 0, token.length() - 1)
  }
  token
}

///|
fn filter_task_terms(
  terms : Array[String],
  briefs : Array[LocalFileBrief],
) -> Array[String] {
  if briefs.is_empty() {
    return terms
  }
  let ranked : Array[LocalTermRank] = []
  for term in terms {
    let mut owner_docs = 0
    let mut consumer_docs = 0
    for brief in briefs {
      if brief.summary_terms.contains(term) {
        if is_consumer_path(brief.path) {
          consumer_docs += 1
        } else {
          owner_docs += 1
        }
      }
    }
    let docs = owner_docs + consumer_docs
    if docs > 0 && !is_consumer_dominated_term(term, briefs) {
      ranked.push({ term, owner_docs, consumer_docs, all_docs: docs })
    }
  }
  ranked.sort_by(fn(a, b) {
    let a_owner_missing = if a.owner_docs == 0 { 1 } else { 0 }
    let b_owner_missing = if b.owner_docs == 0 { 1 } else { 0 }
    let c = a_owner_missing.compare(b_owner_missing)
    if c != 0 {
      return c
    }
    let c = a.owner_docs.compare(b.owner_docs)
    if c != 0 {
      return c
    }
    let c = a.consumer_docs.compare(b.consumer_docs)
    if c != 0 {
      return c
    }
    let c = a.all_docs.compare(b.all_docs)
    if c != 0 {
      c
    } else {
      b.term.length().compare(a.term.length())
    }
  })
  let result : Array[String] = []
  for item in ranked {
    result.push(item.term)
  }
  result
}

///|
fn filter_owner_task_terms(
  terms : Array[String],
  orient_map : AgentOrientMap,
) -> Array[String] {
  if orient_map.owners.is_empty() {
    return terms
  }
  let ranked : Array[LocalTermRank] = []
  let owner_terms : Array[Array[String]] = []
  for owner in orient_map.owners {
    owner_terms.push(task_tokens(owner.summary))
  }
  for term in terms {
    let mut owner_docs = 0
    for tokens in owner_terms {
      if tokens.contains(term) {
        owner_docs += 1
      }
    }
    if owner_docs > 0 {
      ranked.push({ term, owner_docs, consumer_docs: 0, all_docs: owner_docs })
    }
  }
  ranked.sort_by(fn(a, b) {
    let c = a.owner_docs.compare(b.owner_docs)
    if c != 0 {
      c
    } else {
      b.term.length().compare(a.term.length())
    }
  })
  let result : Array[String] = []
  for item in ranked {
    result.push(item.term)
  }
  result
}

///|
fn owner_task_terms_for_task(
  task : String,
  raw_terms : Array[String],
  orient_map : AgentOrientMap,
) -> Array[String] {
  let objective_terms = objective_task_terms(task, raw_terms)
  let focused = filter_owner_task_terms(objective_terms, orient_map)
  if focused.length() >= 2 {
    focused
  } else {
    filter_owner_task_terms(raw_terms, orient_map)
  }
}

///|
fn objective_task_terms(
  task : String,
  raw_terms : Array[String],
) -> Array[String] {
  let primary = task_tokens(first_task_sentence(task))
  if primary.length() < 3 {
    return raw_terms
  }
  let result : Array[String] = []
  for term in primary {
    if raw_terms.contains(term) && !result.contains(term) {
      result.push(term)
    }
  }
  if result.length() < 3 {
    raw_terms
  } else {
    result
  }
}

///|
fn first_task_sentence(task : String) -> String {
  let result = StringBuilder::new()
  for ch in task {
    if ch == '.' || ch == '!' || ch == '?' || ch == '\n' {
      break
    }
    result.write_char(ch)
  }
  let sentence = result.to_string().trim().to_owned()
  if sentence.length() == 0 {
    task
  } else {
    sentence
  }
}

///|
fn is_consumer_dominated_term(
  term : String,
  briefs : Array[LocalFileBrief],
) -> Bool {
  let mut consumer_docs = 0
  let mut owner_docs = 0
  for brief in briefs {
    if !brief.structural_terms.contains(term) {
      continue
    }
    if is_consumer_path(brief.path) {
      consumer_docs += 1
    } else {
      owner_docs += 1
    }
  }
  consumer_docs >= 3 && consumer_docs > owner_docs
}

///|
fn score_briefs(
  briefs : Array[LocalFileBrief],
  task_terms : Array[String],
  task : String,
) -> Array[LocalFileBrief] {
  let result : Array[LocalFileBrief] = []
  for brief in briefs {
    let structural_matched = matched_terms_in_tokens(
      task_terms,
      brief.structural_terms,
    )
    let matched = if structural_matched.length() > 0 {
      structural_matched
    } else {
      matched_terms_in_tokens(task_terms, brief.summary_terms)
    }
    result.push({
      path: brief.path,
      source_hash: brief.source_hash,
      structural_summary: brief.structural_summary,
      summary: brief.summary,
      structural_terms: brief.structural_terms,
      summary_terms: brief.summary_terms,
      score: orientation_score(
        task,
        brief.structural_summary,
        task_terms,
        matched.length(),
      ),
      matched_terms: matched,
    })
  }
  result
}

///|
fn matched_terms_in_tokens(
  task_terms : Array[String],
  text_terms : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for term in task_terms {
    if text_terms.contains(term) {
      result.push(term)
    }
  }
  result
}

///|
pub fn orient_map_path(config : AgentOrientConfig) -> String {
  config.cache_dir + "/orient-map.json"
}

///|
fn load_cached_orient_map(config : AgentOrientConfig) -> AgentOrientMap? {
  let path = orient_map_path(config)
  let content = @fs.read_file_to_string(path) catch { _ => return None }
  let json = @json.parse(content) catch { _ => return None }
  let map : AgentOrientMap = @json.from_json(json) catch { _ => return None }
  if map.version == "agent-orient-map-v1" {
    Some(map)
  } else {
    None
  }
}

///|
fn save_orient_map(config : AgentOrientConfig, map : AgentOrientMap) -> Unit {
  @config_paths.ensure_dir_recursive(config.cache_dir)
  @fs.write_string_to_file(
    orient_map_path(config),
    map.to_json().stringify(indent=2) + "\n",
  ) catch {
    _ => ()
  }
}

///|
fn build_or_update_orient_map(
  config : AgentOrientConfig,
  briefs : Array[LocalFileBrief],
  cached_map : AgentOrientMap?,
) -> AgentOrientMap {
  if config.no_update {
    match cached_map {
      Some(map) => return { ..map, status: map_status_for_cached(map) }
      None => ()
    }
  }
  let old_hashes : Map[String, String] = {}
  match cached_map {
    Some(map) =>
      for file in map.files {
        old_hashes.set(file.path, file.source_hash)
      }
    None => ()
  }
  let current_hashes : Map[String, String] = {}
  let files : Array[AgentOrientMapFile] = []
  let changed : Array[String] = []
  let new_files : Array[String] = []
  for brief in briefs {
    current_hashes.set(brief.path, brief.source_hash)
    files.push({
      path: brief.path,
      source_hash: brief.source_hash,
      owner: owner_dir(brief.path),
      structural_summary: brief.structural_summary,
      summary: brief.summary,
    })
    match old_hashes.get(brief.path) {
      Some(hash) if hash == brief.source_hash => ()
      Some(_) => changed.push(brief.path)
      None => new_files.push(brief.path)
    }
  }
  let deleted : Array[String] = []
  for entry in old_hashes {
    if !current_hashes.contains(entry.0) {
      deleted.push(entry.0)
    }
  }
  let owner_dirs = owner_dirs_from_files(files)
  let wiki_docs = collect_wiki_docs(config.wiki_dir, owner_dirs)
  let knowledge_hash = orient_knowledge_hash(wiki_docs)
  let knowledge_changed = match cached_map {
    Some(map) => map.knowledge_hash != knowledge_hash
    None => true
  }
  let affected_owners = affected_owner_dirs(
    changed, new_files, deleted, owner_dirs, knowledge_changed, cached_map,
  )
  let owners = build_owner_map_entries(
    files, wiki_docs, cached_map, affected_owners,
  )
  let reused = reused_owner_dirs(owners, affected_owners)
  let doc_count = owner_doc_source_count(owners)
  {
    version: "agent-orient-map-v1",
    knowledge_hash,
    files,
    owners,
    status: {
      total_files: files.length(),
      total_owners: owners.length(),
      total_doc_sources: doc_count,
      changed_files: changed,
      new_files,
      deleted_files: deleted,
      knowledge_changed,
      refreshed_owners: affected_owners,
      reused_owners: reused,
    },
  }
}

///|
fn map_status_for_cached(map : AgentOrientMap) -> AgentOrientMapStatus {
  {
    total_files: map.files.length(),
    total_owners: map.owners.length(),
    total_doc_sources: owner_doc_source_count(map.owners),
    changed_files: [],
    new_files: [],
    deleted_files: [],
    knowledge_changed: false,
    refreshed_owners: [],
    reused_owners: owner_paths(map.owners),
  }
}

///|
fn owner_paths(owners : Array[AgentOrientMapOwner]) -> Array[String] {
  let result : Array[String] = []
  for owner in owners {
    result.push(owner.path)
  }
  result
}

///|
fn owner_doc_source_count(owners : Array[AgentOrientMapOwner]) -> Int {
  let mut count = 0
  for owner in owners {
    count += owner.doc_sources.length()
  }
  count
}

///|
fn affected_owner_dirs(
  changed : Array[String],
  new_files : Array[String],
  deleted : Array[String],
  owner_dirs : Array[String],
  knowledge_changed : Bool,
  cached_map : AgentOrientMap?,
) -> Array[String] {
  let dirs : Array[String] = []
  if knowledge_changed {
    for dir in owner_dirs {
      push_unique_dir(dirs, dir)
    }
  }
  for path in changed {
    push_unique_dir(dirs, owner_dir(path))
  }
  for path in new_files {
    push_unique_dir(dirs, owner_dir(path))
  }
  for path in deleted {
    match cached_map {
      Some(map) =>
        for file in map.files {
          if file.path == path {
            push_unique_dir(dirs, file.owner)
          }
        }
      None => push_unique_dir(dirs, owner_dir(path))
    }
  }
  dirs
}

///|
fn build_owner_map_entries(
  files : Array[AgentOrientMapFile],
  wiki_docs : Array[LocalDocSource],
  cached_map : AgentOrientMap?,
  affected_owners : Array[String],
) -> Array[AgentOrientMapOwner] {
  let dirs = owner_dirs_from_files(files)
  let owners : Array[AgentOrientMapOwner] = []
  for dir in dirs {
    match cached_owner_for(dir, cached_map) {
      Some(owner) =>
        if !affected_owners.contains(dir) &&
          owner_files_still_match(owner, files) {
          owners.push(owner)
        } else {
          owners.push(build_owner_map_entry(dir, files, wiki_docs))
        }
      _ => owners.push(build_owner_map_entry(dir, files, wiki_docs))
    }
  }
  owners
}

///|
fn owner_dirs_from_files(files : Array[AgentOrientMapFile]) -> Array[String] {
  let dirs : Array[String] = []
  for file in files {
    if is_consumer_path(file.path) {
      continue
    }
    push_unique_dir(dirs, file.owner)
  }
  dirs
}

///|
fn cached_owner_for(
  dir : String,
  cached_map : AgentOrientMap?,
) -> AgentOrientMapOwner? {
  match cached_map {
    None => None
    Some(map) => {
      for owner in map.owners {
        if owner.path == dir {
          return Some(owner)
        }
      }
      None
    }
  }
}

///|
fn owner_files_still_match(
  owner : AgentOrientMapOwner,
  files : Array[AgentOrientMapFile],
) -> Bool {
  let current : Array[String] = []
  for file in files {
    if file.owner == owner.path && !is_consumer_path(file.path) {
      current.push(file.path)
    }
  }
  current.sort()
  let expected = owner.files.copy()
  expected.sort()
  current == expected
}

///|
fn build_owner_map_entry(
  dir : String,
  files : Array[AgentOrientMapFile],
  wiki_docs : Array[LocalDocSource],
) -> AgentOrientMapOwner {
  let owner_files : Array[String] = []
  let doc_sources : Array[String] = []
  let summary = StringBuilder::new()
  summary.write_string(dir)
  summary.write_string("\n")
  let hashes : Array[String] = []
  summary.write_string("Documentation knowledge\n")
  for file in files {
    if file.owner != dir || is_consumer_path(file.path) {
      continue
    }
    owner_files.push(file.path)
    hashes.push(file.source_hash)
    if is_documentation_path(file.path) {
      doc_sources.push(file.path)
      summary.write_string(file.summary)
      summary.write_string("\n")
    }
  }
  for doc in wiki_docs {
    if doc.owner == dir {
      doc_sources.push(doc.path)
      hashes.push(doc.source_hash)
      summary.write_string(doc.content)
      summary.write_string("\n")
    }
  }
  summary.write_string("Code structure\n")
  for file in files {
    if file.owner != dir ||
      is_consumer_path(file.path) ||
      is_documentation_path(file.path) {
      continue
    }
    summary.write_string(file.structural_summary)
    summary.write_string("\n")
  }
  owner_files.sort()
  hashes.sort()
  doc_sources.sort()
  {
    path: dir,
    source_hash: @cas_hash.compute_hash(hashes.join("\n")).to_string(),
    files: owner_files,
    doc_sources,
    summary: summary.to_string(),
  }
}

///|
fn reused_owner_dirs(
  owners : Array[AgentOrientMapOwner],
  affected_owners : Array[String],
) -> Array[String] {
  let reused : Array[String] = []
  for owner in owners {
    if !affected_owners.contains(owner.path) {
      reused.push(owner.path)
    }
  }
  reused
}

///|
fn push_unique_dir(dirs : Array[String], dir : String) -> Unit {
  if dir.length() > 0 && !is_consumer_path(dir) && !dirs.contains(dir) {
    dirs.push(dir)
  }
}

///|
fn collect_wiki_docs(
  wiki_dir : String,
  owner_dirs : Array[String],
) -> Array[LocalDocSource] {
  let result : Array[LocalDocSource] = []
  let manifest = load_wiki_manifest(wiki_dir)
  match manifest {
    None => result
    Some(m) => {
      for page in m.pages {
        if !wiki_page_is_owner_specific(page) {
          continue
        }
        let content_path = wiki_dir + "/" + page.file
        let content = @fs.read_file_to_string(content_path) catch {
          _ => continue
        }
        for owner in owner_dirs {
          if !wiki_page_covers_owner(page, owner) {
            continue
          }
          let doc_path = content_path + "#" + page.id
          if doc_source_exists(result, doc_path, owner) {
            continue
          }
          result.push({
            path: doc_path,
            owner,
            source_hash: @cas_hash.compute_hash(content).to_string(),
            content: "Wiki page " + page.id + " " + page.title + "\n" + content,
          })
        }
      }
      result
    }
  }
}

///|
fn load_wiki_manifest(wiki_dir : String) -> LocalWikiManifest? {
  let content = @fs.read_file_to_string(wiki_dir + "/wiki.json") catch {
    _ => return None
  }
  let json = @json.parse(content) catch { _ => return None }
  let manifest : LocalWikiManifest = @json.from_json(json) catch {
    _ => return None
  }
  Some(manifest)
}

///|
fn wiki_page_is_owner_specific(page : LocalWikiPage) -> Bool {
  page.sources.length() == 1
}

///|
fn wiki_page_covers_owner(page : LocalWikiPage, owner : String) -> Bool {
  for source in page.sources {
    if source_matches_owner(source, owner) {
      return true
    }
  }
  false
}

///|
fn source_matches_owner(source : String, owner : String) -> Bool {
  let source_path = trim_trailing_slash(source)
  let owner_path = trim_trailing_slash(owner)
  source_path == owner_path || source_path.has_prefix(owner_path + "/")
}

///|
fn trim_trailing_slash(path : String) -> String {
  let mut end = path.length()
  while end > 0 && path[end - 1] == '/' {
    end -= 1
  }
  @config_paths.substring(path, 0, end)
}

///|
fn doc_source_exists(
  docs : Array[LocalDocSource],
  path : String,
  owner : String,
) -> Bool {
  for doc in docs {
    if doc.path == path && doc.owner == owner {
      return true
    }
  }
  false
}

///|
fn orient_knowledge_hash(wiki_docs : Array[LocalDocSource]) -> String {
  let parts : Array[String] = []
  for doc in wiki_docs {
    parts.push(doc.owner + "\t" + doc.path + "\t" + doc.source_hash)
  }
  parts.sort()
  @cas_hash.compute_hash(parts.join("\n")).to_string()
}

///|
fn is_documentation_path(path : String) -> Bool {
  path.has_suffix(".md") || path.has_suffix(".mbt.md")
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
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
  limit : Int,
) -> Array[AgentOrientItem] {
  let owner_briefs = score_owner_briefs(orient_map, task_terms, task)
  let result : Array[AgentOrientItem] = []
  for brief in owner_briefs {
    if brief.score <= 0.0 {
      continue
    }
    result.push({
      path: brief.path,
      reason: "Closest non-CLI directory concept profile for task terms: " +
      brief.matched_terms.join(", "),
    })
    if result.length() >= limit {
      break
    }
  }
  result
}

///|
fn score_owner_briefs(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
  task : String,
) -> Array[LocalOwnerBrief] {
  let result : Array[LocalOwnerBrief] = []
  let owner_doc_counts = build_owner_doc_counts(orient_map, task_terms)
  for owner in orient_map.owners {
    let owner_tokens = task_tokens(owner.summary)
    let dir = owner.path
    let summary = owner.summary
    let matched = matched_terms_in_tokens(task_terms, owner_tokens)
    result.push({
      path: dir,
      score: owner_orientation_score(
        task,
        summary,
        task_terms,
        matched,
        owner_doc_counts,
        orient_map.owners.length(),
      ),
      matched_terms: matched,
    })
  }
  result.sort_by(fn(a, b) {
    let c = b.score.compare(a.score)
    if c != 0 {
      c
    } else {
      a.path.compare(b.path)
    }
  })
  result
}

///|
fn owner_orientation_score(
  task : String,
  summary : String,
  task_terms : Array[String],
  matched : Array[String],
  owner_doc_counts : Map[String, Int],
  owner_count : Int,
) -> Double {
  let docs = [
    @tokenizer.tokenize_for_tfidf(task),
    @tokenizer.tokenize_for_tfidf(summary),
  ]
  let batch = @tfidf.BM25Batch::from_tokens(docs)
  let mut total = 0.0
  let mut hits = 0.0
  for term in task_terms {
    let weight = owner_term_weight(term, owner_doc_counts, owner_count)
    if weight <= 0.0 {
      continue
    }
    total += weight
    if matched.contains(term) {
      hits += weight
    }
  }
  let lexical = if total <= 0.0 { 0.0 } else { hits / total }
  let focus = focused_owner_window_score(
    summary, task_terms, owner_doc_counts, owner_count,
  )
  let score = lexical * 0.3 + focus * 0.35 + batch.similarity(0, 1) * 0.35
  if score > 1.0 {
    1.0
  } else {
    score
  }
}

///|
fn owner_term_weight(
  term : String,
  owner_doc_counts : Map[String, Int],
  owner_count : Int,
) -> Double {
  let docs = owner_doc_counts.get(term).unwrap_or(0)
  if docs == 0 {
    0.0
  } else {
    @math.ln((1.0 + owner_count.to_double()) / (1.0 + docs.to_double())) + 1.0
  }
}

///|
fn focused_owner_window_score(
  summary : String,
  task_terms : Array[String],
  owner_doc_counts : Map[String, Int],
  owner_count : Int,
) -> Double {
  let tokens = task_token_stream(summary)
  if tokens.is_empty() || task_terms.is_empty() {
    return 0.0
  }
  let mut total = 0.0
  for term in task_terms {
    total += owner_term_weight(term, owner_doc_counts, owner_count)
  }
  if total <= 0.0 {
    return 0.0
  }
  let mut best = 0.0
  let mut start = 0
  let window_size = owner_focus_window_size()
  let stride = owner_focus_stride()
  while start < tokens.length() {
    let mut end = start + window_size
    if end > tokens.length() {
      end = tokens.length()
    }
    let seen : Array[String] = []
    for i in start..<end {
      let token = tokens[i]
      if task_terms.contains(token) && !seen.contains(token) {
        seen.push(token)
      }
    }
    let mut hits = 0.0
    for term in seen {
      hits += owner_term_weight(term, owner_doc_counts, owner_count)
    }
    let score = hits / total
    if score > best {
      best = score
    }
    start += stride
  }
  best
}

///|
fn task_token_stream(text : String) -> Array[String] {
  let result : Array[String] = []
  for token in @tokenizer.extract_word_tokens(@tokenizer.normalize_text(text)) {
    append_orient_token(result, token)
    for part in split_orient_token(token) {
      append_orient_token(result, part)
    }
  }
  result
}

///|
fn append_orient_token(result : Array[String], token : String) -> Unit {
  let canonical = canonical_orient_token(token)
  if canonical.length() >= 2 {
    result.push(canonical)
  }
}

///|
fn owner_focus_window_size() -> Int {
  80
}

///|
fn owner_focus_stride() -> Int {
  24
}

///|
fn build_owner_doc_counts(
  orient_map : AgentOrientMap,
  task_terms : Array[String],
) -> Map[String, Int] {
  let counts : Map[String, Int] = {}
  for owner in orient_map.owners {
    let tokens = task_tokens(owner.summary)
    for term in task_terms {
      if tokens.contains(term) {
        counts[term] = counts.get(term).unwrap_or(0) + 1
      }
    }
  }
  counts
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
    "Use doc graph, grep, search, explore, and relevant audit commands to confirm the chosen owner.",
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
  } else if is_consumer_path(path) {
    "consumer"
  } else if path.has_suffix(".md") {
    "documentation"
  } else {
    "implementation"
  }
}

///|
fn is_consumer_path(path : String) -> Bool {
  is_cli_path(path) ||
  is_cmd_path(path) ||
  path.has_prefix("skills/") ||
  path.contains("/skills/")
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
fn is_cmd_path(path : String) -> Bool {
  path.has_prefix("cmd/") || path.contains("/cmd/")
}

///|
fn readiness_quiz(
  owners : Array[AgentOrientItem],
  consumers : Array[AgentOrientItem],
  forbidden : Array[AgentOrientItem],
  preflight : Array[AgentOrientItem],
) -> Array[AgentOrientQuizItem] {
  let quiz : Array[AgentOrientQuizItem] = []
  if owners.length() > 0 {
    quiz.push({
      question: "Which implementation area should own the first core change?",
      expected_answer: owners[0].path,
      evidence_path: owners[0].path,
    })
  }
  if forbidden.length() > 0 {
    quiz.push({
      question: "Name one path where domain logic must not be added.",
      expected_answer: forbidden[0].path,
      evidence_path: forbidden[0].path,
    })
  } else if consumers.length() > 0 {
    quiz.push({
      question: "Name one consumer surface that should call core APIs instead of owning domain logic.",
      expected_answer: consumers[0].path,
      evidence_path: consumers[0].path,
    })
  }
  if preflight.length() > 0 {
    let evidence = first_owner_preflight(preflight)
    quiz.push({
      question: "Which evidence path should be read before editing?",
      expected_answer: evidence.path,
      evidence_path: evidence.path,
    })
  }
  quiz
}

///|
fn first_owner_preflight(preflight : Array[AgentOrientItem]) -> AgentOrientItem {
  for item in preflight {
    if !is_consumer_path(item.path) {
      return item
    }
  }
  preflight[0]
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
