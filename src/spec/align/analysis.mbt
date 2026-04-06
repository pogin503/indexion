///|
fn current_epoch_seconds() -> Int {
  (@env.now() / 1000UL).to_int()
}

///|
fn trim(text : String) -> String {
  @common.trim_ascii_spaces(text)
}

///|
fn lower_ascii(text : String) -> String {
  @kgf_features.to_lower_str(text)
}

///|
fn is_blank(text : String) -> Bool {
  trim(text).length() == 0
}

///|
fn config_hash(config : SpecAlignConfig) -> String {
  let joined = [
    config.spec_path,
    config.impl_path,
    config.spec_format,
    config.algorithm,
    config.threshold.to_string(),
  ].join("\u0001")
  @cas_hash.compute_hash(joined).to_string()
}

///|
let project_root_markers : Array[String] = [
  ".git", ".indexion", ".indexion.toml", ".indexion.json",
]

///|
fn file_exists(path : String) -> Bool {
  @fs.path_exists(path)
}

///|
fn path_is_dir(path : String) -> Bool {
  @fs.is_dir(path) catch {
    err => {
      println(
        "Error: failed to inspect path `" + path + "`: " + err.to_string(),
      )
      false
    }
  }
}

///|
fn is_spec_file_path(path : String, registry : @registry.KGFRegistry) -> Bool {
  match @kgf_features.is_document_file(path, Some(registry)) {
    Some(is_document) => is_document
    None => false
  }
}

///|
fn discover_spec_files(
  spec_path : String,
  registry : @registry.KGFRegistry,
) -> Array[String] {
  if spec_path.length() == 0 || !file_exists(spec_path) {
    return []
  }
  if !path_is_dir(spec_path) {
    return if is_spec_file_path(spec_path, registry) { [spec_path] } else { [] }
  }
  let discovered = @pipeline.discover_files(
    [spec_path],
    @pipeline.DiscoverOptions::new(),
  )
  let result : Array[String] = []
  for path in discovered {
    if is_spec_file_path(path, registry) {
      result.push(path)
    }
  }
  result.sort()
  result
}

///|
fn is_impl_file_path(path : String, registry : @registry.KGFRegistry) -> Bool {
  match registry.detect_from_path(path) {
    Some(name) =>
      match registry.get_spec(name) {
        Some(spec) => !@kgf_features.is_document_spec(spec)
        None => false
      }
    None => false
  }
}

///|
fn discover_impl_files(
  impl_path : String,
  registry : @registry.KGFRegistry,
) -> Array[String] {
  if impl_path.length() == 0 || !file_exists(impl_path) {
    return []
  }
  if !path_is_dir(impl_path) {
    return if is_impl_file_path(impl_path, registry) { [impl_path] } else { [] }
  }
  let kgf_ignore = registry.collect_ignore_patterns()
  let discovered = @pipeline.discover_files(
    [impl_path],
    @pipeline.DiscoverOptions::new(kgf_ignore~),
  )
  let result : Array[String] = []
  for path in discovered {
    if is_impl_file_path(path, registry) {
      result.push(path)
    }
  }
  result.sort()
  result
}

///|
fn tracking_root(config : SpecAlignConfig) -> String {
  let anchor = if config.impl_path.length() > 0 {
    config.impl_path
  } else {
    config.spec_path
  }
  let start = if path_is_dir(anchor) { anchor } else { @config.dirname(anchor) }
  match @config.find_project_root(start, project_root_markers) {
    Some(root) => root
    None => start
  }
}

///|
fn requirement_excerpt(requirement : RequirementNode) -> String {
  if requirement.description.length() > 0 {
    requirement.description
  } else if requirement.criteria.length() > 0 {
    requirement.criteria[0]
  } else {
    requirement.title
  }
}

///|
fn implementation_excerpt(implementation : ImplementationNode) -> String {
  if implementation.declaration_text.length() > 0 {
    implementation.declaration_text
  } else if implementation.signature.length() > 0 {
    implementation.signature
  } else {
    implementation.name
  }
}

///|
async fn collect_spec_data(
  config : SpecAlignConfig,
  registry : @registry.KGFRegistry,
) -> (
  Array[RequirementNode],
  Array[ScenarioNode],
  Array[String],
  Map[String, String],
  Array[@reconcile_tracking.FileState],
) {
  let requirements : Array[RequirementNode] = []
  let scenarios : Array[ScenarioNode] = []
  let used_specs : Array[String] = []
  let file_hashes : Map[String, String] = {}
  let file_states : Array[@reconcile_tracking.FileState] = []
  let spec_files = discover_spec_files(config.spec_path, registry)
  let root = tracking_root(config)
  let tracking_config = @reconcile_tracking.FileTrackingConfig::new(true, true)
  for path in spec_files {
    let content = @fs.read_file_to_string(path) catch {
      err => {
        println(
          "Error: failed to read spec file `" + path + "`: " + err.to_string(),
        )
        return ([], [], [], {}, [])
      }
    }
    let (reqs, scns, used_spec) = parse_spec_document(
      path,
      content,
      config.spec_format,
      registry,
    )
    for requirement in reqs {
      requirements.push(requirement)
    }
    for scenario in scns {
      scenarios.push(scenario)
    }
    if used_spec != "unsupported" && !used_specs.contains(used_spec) {
      used_specs.push(used_spec)
    }
    let content_hash = @cas_hash.compute_hash(content).to_string()
    file_hashes.set(path, content_hash)
    let ts = @reconcile_tracking.timestamp_for_path(root, path, tracking_config)
    file_states.push(
      @reconcile_tracking.FileState::new(
        path,
        "spec",
        used_spec,
        content_hash,
        ts.epoch_seconds,
        @git.file_mtime_seconds(path),
        ts.is_dirty,
      ),
    )
  }
  (requirements, scenarios, used_specs, file_hashes, file_states)
}

///|
fn safe_line(content : String, line_no : Int) -> String {
  let lines = @common.split_lines(content)
  if line_no <= 0 || line_no > lines.length() {
    return ""
  }
  trim(lines[line_no - 1])
}

///|
fn context_excerpt(
  content : String,
  line_no : Int,
  before : Int,
  after : Int,
) -> String {
  let lines = @common.split_lines(content)
  if lines.length() == 0 {
    return ""
  }
  let start = if line_no - before < 1 { 1 } else { line_no - before }
  let end_ = if line_no + after > lines.length() {
    lines.length()
  } else {
    line_no + after
  }
  let excerpt : Array[String] = []
  for i = start; i <= end_; i = i + 1 {
    let value = trim(lines[i - 1])
    if value.length() > 0 {
      excerpt.push(value)
    }
  }
  excerpt.join("\n")
}

///|
fn append_implementation_node(
  implementations : Array[ImplementationNode],
  content : String,
  path : String,
  kind : String,
  name : String,
  line : Int,
  doc_map : Map[Int, String],
) -> Unit {
  let signature = safe_line(content, line)
  let declaration_text = context_excerpt(content, line, 2, 3)
  implementations.push({
    id: path + "::" + name,
    name,
    kind,
    file: path,
    start_line: line,
    end_line: line,
    signature,
    declaration_text,
    doc_comment: doc_map.get(line),
  })
}

///|
async fn collect_impl_data(
  config : SpecAlignConfig,
  registry : @registry.KGFRegistry,
) -> (
  Array[ImplementationNode],
  Array[String],
  Map[String, String],
  Map[String, String],
  Array[@reconcile_tracking.FileState],
) {
  let implementations : Array[ImplementationNode] = []
  let used_specs : Array[String] = []
  let file_hashes : Map[String, String] = {}
  let file_contents : Map[String, String] = {}
  let file_states : Array[@reconcile_tracking.FileState] = []
  let impl_files = discover_impl_files(config.impl_path, registry)
  let root = tracking_root(config)
  let tracking_config = @reconcile_tracking.FileTrackingConfig::new(true, true)
  for path in impl_files {
    let content = @fs.read_file_to_string(path) catch {
      err => {
        println(
          "Error: failed to read implementation file `" +
          path +
          "`: " +
          err.to_string(),
        )
        return ([], [], {}, {}, [])
      }
    }
    file_contents.set(path, content)
    let content_hash = @cas_hash.compute_hash(content).to_string()
    file_hashes.set(path, content_hash)
    let detected_spec = match registry.detect_from_path(path) {
      Some(name) => {
        if !used_specs.contains(name) {
          used_specs.push(name)
        }
        name
      }
      None => "code"
    }
    let ts = @reconcile_tracking.timestamp_for_path(root, path, tracking_config)
    file_states.push(
      @reconcile_tracking.FileState::new(
        path,
        "impl",
        detected_spec,
        content_hash,
        ts.epoch_seconds,
        @git.file_mtime_seconds(path),
        ts.is_dirty,
      ),
    )
    let (kgf_declarations, doc_map) = @kgf_features.extract_pub_declarations_and_doc_map(
      content,
      path,
      Some(registry),
    )
    let seen : Map[String, Bool] = {}
    for declaration in kgf_declarations {
      let key = declaration.name + "@" + declaration.line.to_string()
      if seen.contains(key) {
        continue
      }
      seen.set(key, true)
      append_implementation_node(
        implementations,
        content,
        path,
        declaration.kind,
        declaration.name,
        declaration.line,
        doc_map,
      )
    }
  }
  (implementations, used_specs, file_hashes, file_contents, file_states)
}

///|
fn requirement_text(
  requirement : RequirementNode,
  scenarios : Array[ScenarioNode],
) -> String {
  let buf = StringBuilder::new()
  buf.write_string(requirement.title)
  buf.write_string("\n")
  buf.write_string(requirement.description)
  buf.write_string("\n")
  for criterion in requirement.criteria {
    buf.write_string(criterion)
    buf.write_string("\n")
  }
  for scenario in scenarios {
    if scenario.parent_req != requirement.id {
      continue
    }
    for item in scenario.given {
      buf.write_string(item)
      buf.write_string("\n")
    }
    for item in scenario.when_ {
      buf.write_string(item)
      buf.write_string("\n")
    }
    for item in scenario.then_ {
      buf.write_string(item)
      buf.write_string("\n")
    }
  }
  buf.to_string()
}

///|
fn implementation_text(implementation : ImplementationNode) -> String {
  let buf = StringBuilder::new()
  buf.write_string(implementation.name)
  buf.write_string("\n")
  buf.write_string(normalize_identifier_words(implementation.name))
  buf.write_string("\n")
  buf.write_string(implementation.signature)
  buf.write_string("\n")
  buf.write_string(implementation.declaration_text)
  buf.write_string("\n")
  match implementation.doc_comment {
    Some(doc) => buf.write_string(doc)
    None => ()
  }
  buf.to_string()
}

///|
fn normalize_identifier_words(text : String) -> String {
  let buf = StringBuilder::new()
  let chars = text.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    let ch = chars[i]
    let prev = if i > 0 { Some(chars[i - 1]) } else { None }
    if ch == '_' || ch == '-' {
      buf.write_char(' ')
      continue
    }
    match prev {
      Some(p) =>
        if ch >= 'A' &&
          ch <= 'Z' &&
          ((p >= 'a' && p <= 'z') || (p >= '0' && p <= '9')) {
          buf.write_char(' ')
        }
      None => ()
    }
    buf.write_char(ch)
  }
  lower_ascii(buf.to_string())
}

///|
fn clamp_similarity(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn tfidf_similarity(a : String, b : String) -> Double {
  let tokens_a = @tokenizer.tokenize_for_tfidf(a)
  let tokens_b = @tokenizer.tokenize_for_tfidf(b)
  if tokens_a.length() == 0 || tokens_b.length() == 0 {
    return 0.0
  }
  let distance = @tfidf.calculate_tfidf_distance_from_tokens(tokens_a, tokens_b)
  clamp_similarity(1.0 - distance)
}

///|
fn ncd_similarity(a : String, b : String) -> Double {
  clamp_similarity(1.0 - @ncd.NCDStrategy::new().distance(a, b))
}

///|
fn score_texts(a : String, b : String, algorithm : String) -> Double {
  let tfidf = tfidf_similarity(a, b)
  let ncd = ncd_similarity(a, b)
  match algorithm {
    "tfidf" => tfidf
    "ncd" => ncd
    _ => clamp_similarity((tfidf + ncd) / 2.0)
  }
}

///|
fn literals_from_text(text : String) -> Array[String] {
  let values : Array[String] = []
  let numeric : Array[Char] = []
  let quoted : Array[Char] = []
  let mut in_backtick = false

  fn flush_numeric(values : Array[String], numeric : Array[Char]) -> Unit {
    if numeric.length() >= 2 {
      let value = String::from_array(numeric)
      if !values.contains(value) {
        values.push(value)
      }
    }
    numeric.clear()
  }

  fn flush_quoted(values : Array[String], quoted : Array[Char]) -> Unit {
    if quoted.length() > 0 {
      let value = String::from_array(quoted)
      if !values.contains(value) {
        values.push(value)
      }
    }
    quoted.clear()
  }

  for ch in text.to_array() {
    if ch == '`' {
      if in_backtick {
        flush_quoted(values, quoted)
      }
      in_backtick = !in_backtick
      flush_numeric(values, numeric)
      continue
    }
    if in_backtick {
      quoted.push(ch)
      continue
    }
    if ch >= '0' && ch <= '9' {
      numeric.push(ch)
    } else {
      flush_numeric(values, numeric)
    }
  }
  flush_numeric(values, numeric)
  flush_quoted(values, quoted)
  values
}

///|
fn build_trace_edges(
  requirements : Array[RequirementNode],
  scenarios : Array[ScenarioNode],
  implementations : Array[ImplementationNode],
  config : SpecAlignConfig,
) -> Array[TraceEdge] {
  let edges : Array[TraceEdge] = []
  for requirement in requirements {
    let scored : Array[(String, Double)] = []
    let req_text = requirement_text(requirement, scenarios)
    for implementation in implementations {
      let base_score = score_texts(
        req_text,
        implementation_text(implementation),
        config.algorithm,
      )
      let title_score = tfidf_similarity(
        requirement.title,
        normalize_identifier_words(implementation.name),
      )
      let score = if title_score > base_score {
        title_score
      } else {
        base_score
      }
      scored.push((implementation.id, score))
    }
    scored.sort_by(fn(a, b) { b.1.compare(a.1) })
    let limit = if scored.length() < 3 { scored.length() } else { 3 }
    for i = 0; i < limit; i = i + 1 {
      let (implementation_id, score) = scored[i]
      edges.push({
        requirement_id: requirement.id,
        implementation_id,
        confidence: score,
        algorithm: config.algorithm,
        status: if score >= config.threshold {
          "matched"
        } else {
          "unmatched"
        },
        rank: i,
      })
    }
  }
  edges
}

///|
fn best_edge_for_requirement(
  edges : Array[TraceEdge],
  requirement_id : String,
) -> TraceEdge? {
  for edge in edges {
    if edge.requirement_id == requirement_id && edge.rank == 0 {
      return Some(edge)
    }
  }
  None
}

///|
fn implementation_by_id(
  implementations : Array[ImplementationNode],
  implementation_id : String,
) -> ImplementationNode? {
  for implementation in implementations {
    if implementation.id == implementation_id {
      return Some(implementation)
    }
  }
  None
}

///|
fn find_previous_edge(
  previous : AlignSnapshot?,
  requirement_id : String,
) -> TraceEdge? {
  match previous {
    Some(snapshot) => {
      for edge in snapshot.trace_edges {
        if edge.requirement_id == requirement_id && edge.rank == 0 {
          return Some(edge)
        }
      }
      None
    }
    None => None
  }
}

///|
fn file_hash_changed(
  previous : AlignSnapshot?,
  path : String,
  current_hash : String,
) -> Bool {
  match previous {
    Some(snapshot) =>
      match snapshot.file_hashes.get(path) {
        Some(old_hash) => old_hash != current_hash
        None => true
      }
    None => false
  }
}

///|
fn diff_item_for_requirement(
  requirement : RequirementNode,
  scenarios : Array[ScenarioNode],
  best_edge : TraceEdge?,
  matched_implementation : ImplementationNode?,
  config : SpecAlignConfig,
  previous : AlignSnapshot?,
  file_hashes : Map[String, String],
  file_contents : Map[String, String],
) -> AlignDiffItem {
  match (best_edge, matched_implementation) {
    (Some(edge), Some(implementation_node)) => {
      let reasons : Array[String] = []
      let previous_edge = find_previous_edge(previous, requirement.id)
      let previous_confidence = match previous_edge {
        Some(value) => Some(value.confidence)
        None => None
      }
      let file_text = file_contents.get(implementation_node.file).unwrap_or("")
      let missing_literals : Array[String] = []
      for
        literal in literals_from_text(requirement_text(requirement, scenarios)) {
        if literal.length() > 0 && !file_text.contains(literal) {
          missing_literals.push(literal)
        }
      }
      let score_drop = match previous_edge {
        Some(value) =>
          if value.implementation_id == implementation_node.id {
            value.confidence - edge.confidence
          } else {
            0.0
          }
        None => 0.0
      }
      let mut category = "MATCHED"
      if edge.confidence < config.threshold {
        category = "SPEC_ONLY"
        reasons.push(
          "No implementation matched above the similarity threshold.",
        )
      } else if missing_literals.length() > 0 {
        category = "DRIFTED"
        reasons.push(
          "Required literals not found in implementation: `" +
          missing_literals.join("`, `") +
          "`.",
        )
      } else if score_drop >= 0.3 {
        category = "DRIFTED"
        reasons.push(
          "Similarity dropped materially from the previous snapshot.",
        )
      } else {
        reasons.push("Best implementation match remains above threshold.")
      }
      if category == "DRIFTED" &&
        file_hash_changed(
          previous,
          requirement.source_file,
          file_hashes.get(requirement.source_file).unwrap_or(""),
        ) &&
        file_hash_changed(
          previous,
          implementation_node.file,
          file_hashes.get(implementation_node.file).unwrap_or(""),
        ) {
        category = "CONFLICT"
        reasons.push(
          "Both spec and implementation changed since the last snapshot.",
        )
      }
      {
        category,
        requirement_id: Some(requirement.id),
        requirement_title: Some(requirement.title),
        implementation_id: Some(implementation_node.id),
        implementation_name: Some(implementation_node.name),
        confidence: edge.confidence,
        previous_confidence,
        reasons,
        spec_file: Some(requirement.source_file),
        spec_line: Some(requirement.source_start_line),
        impl_file: Some(implementation_node.file),
        impl_line: Some(implementation_node.start_line),
        spec_excerpt: Some(requirement_excerpt(requirement)),
        impl_excerpt: Some(implementation_excerpt(implementation_node)),
      }
    }
    _ =>
      {
        category: "SPEC_ONLY",
        requirement_id: Some(requirement.id),
        requirement_title: Some(requirement.title),
        implementation_id: None,
        implementation_name: None,
        confidence: 0.0,
        previous_confidence: None,
        reasons: [
          "No implementation candidate reached the similarity threshold.",
        ],
        spec_file: Some(requirement.source_file),
        spec_line: Some(requirement.source_start_line),
        impl_file: None,
        impl_line: None,
        spec_excerpt: Some(requirement_excerpt(requirement)),
        impl_excerpt: None,
      }
  }
}

///|
fn build_diff_items(
  requirements : Array[RequirementNode],
  scenarios : Array[ScenarioNode],
  implementations : Array[ImplementationNode],
  edges : Array[TraceEdge],
  config : SpecAlignConfig,
  previous : AlignSnapshot?,
  file_hashes : Map[String, String],
  file_contents : Map[String, String],
) -> Array[AlignDiffItem] {
  let items : Array[AlignDiffItem] = []
  let referenced : Map[String, Bool] = {}
  for requirement in requirements {
    let best_edge = best_edge_for_requirement(edges, requirement.id)
    let matched_implementation = match best_edge {
      Some(edge) =>
        implementation_by_id(implementations, edge.implementation_id)
      None => None
    }
    let item = diff_item_for_requirement(
      requirement, scenarios, best_edge, matched_implementation, config, previous,
      file_hashes, file_contents,
    )
    match item.implementation_id {
      Some(implementation_id) =>
        if item.category != "SPEC_ONLY" {
          referenced.set(implementation_id, true)
        }
      None => ()
    }
    items.push(item)
  }
  for implementation in implementations {
    if referenced.contains(implementation.id) {
      continue
    }
    items.push({
      category: "IMPL_ONLY",
      requirement_id: None,
      requirement_title: None,
      implementation_id: Some(implementation.id),
      implementation_name: Some(implementation.name),
      confidence: 0.0,
      previous_confidence: None,
      reasons: ["Implementation has no requirement match above threshold."],
      spec_file: None,
      spec_line: None,
      impl_file: Some(implementation.file),
      impl_line: Some(implementation.start_line),
      spec_excerpt: None,
      impl_excerpt: Some(implementation_excerpt(implementation)),
    })
  }
  items
}

///|
fn build_summary(
  requirements : Array[RequirementNode],
  implementations : Array[ImplementationNode],
  edges : Array[TraceEdge],
  items : Array[AlignDiffItem],
) -> AlignSummary {
  let mut matched = 0
  let mut drifted = 0
  let mut spec_only = 0
  let mut impl_only = 0
  let mut conflict = 0
  for item in items {
    match item.category {
      "MATCHED" => matched += 1
      "DRIFTED" => drifted += 1
      "SPEC_ONLY" => spec_only += 1
      "IMPL_ONLY" => impl_only += 1
      "CONFLICT" => conflict += 1
      _ => ()
    }
  }
  {
    matched,
    drifted,
    spec_only,
    impl_only,
    conflict,
    total_requirements: requirements.length(),
    total_implementations: implementations.length(),
    total_edges: edges.length(),
  }
}

///|
async fn build_snapshot(
  config : SpecAlignConfig,
  previous : AlignSnapshot?,
) -> AlignSnapshot? {
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dir=config.impl_path,
  )
  let (requirements, scenarios, used_spec_formats, spec_hashes, spec_file_states
  ) = collect_spec_data(config, registry)
  let (
    implementations,
    used_impl_specs,
    impl_hashes,
    file_contents,
    impl_file_states,
  ) = collect_impl_data(config, registry)
  if requirements.length() == 0 && implementations.length() == 0 {
    return None
  }
  let file_hashes : Map[String, String] = {}
  for entry in spec_hashes {
    file_hashes.set(entry.0, entry.1)
  }
  for entry in impl_hashes {
    file_hashes.set(entry.0, entry.1)
  }
  let edges = build_trace_edges(
    requirements, scenarios, implementations, config,
  )
  let diff_items = build_diff_items(
    requirements, scenarios, implementations, edges, config, previous, file_hashes,
    file_contents,
  )
  let summary = build_summary(requirements, implementations, edges, diff_items)
  let used_specs = used_spec_formats + used_impl_specs
  let file_states = spec_file_states + impl_file_states
  Some({
    version: "spec-align-v1",
    generated_at: current_epoch_seconds(),
    config,
    requirements,
    scenarios,
    implementations,
    trace_edges: edges,
    diff_items,
    summary,
    file_hashes,
    source_fingerprint: @reconcile_tracking.build_source_fingerprint(
      config_hash(config),
      file_states,
    ),
    used_specs,
    commit: None,
    history: match previous {
      Some(value) => value.history
      None => []
    },
    cache_hit: false,
  })
}

///|
fn build_diff_report(snapshot : AlignSnapshot) -> AlignDiffReport {
  {
    version: snapshot.version,
    generated_at: snapshot.generated_at,
    config: snapshot.config,
    summary: snapshot.summary,
    items: snapshot.diff_items,
    used_specs: snapshot.used_specs,
    source_fingerprint: snapshot.source_fingerprint,
    commit: snapshot.commit,
    cache_hit: snapshot.cache_hit,
  }
}

///|
fn build_trace_report(snapshot : AlignSnapshot) -> AlignTraceReport {
  {
    version: snapshot.version,
    generated_at: snapshot.generated_at,
    config: snapshot.config,
    summary: snapshot.summary,
    requirements: snapshot.requirements,
    implementations: snapshot.implementations,
    edges: snapshot.trace_edges,
    source_fingerprint: snapshot.source_fingerprint,
    commit: snapshot.commit,
    history: snapshot.history,
    cache_hit: snapshot.cache_hit,
  }
}

///|
fn first_numeric(text : String?) -> String? {
  match text {
    Some(value) => {
      let literals = literals_from_text(value)
      if literals.length() > 0 {
        Some(literals[0])
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn find_substring(text : String, needle : String) -> Int {
  if needle.length() == 0 {
    return 0
  }
  if needle.length() > text.length() {
    return -1
  }
  let limit = text.length() - needle.length()
  for i = 0; i <= limit; i = i + 1 {
    if @common.substring(text, i, i + needle.length()) == needle {
      return i
    }
  }
  -1
}

///|
fn replace_first(text : String, old : String, new_ : String) -> String {
  let idx = find_substring(text, old)
  if idx < 0 {
    return text
  }
  @common.substring(text, 0, idx) +
  new_ +
  @common.substring(text, idx + old.length(), text.length())
}

///|
fn make_numeric_patch(
  path : String,
  before_text : String,
  before_value : String,
  after_value : String,
) -> String {
  let after_text = replace_first(before_text, before_value, after_value)
  "```diff\n--- " +
  path +
  "\n+++ " +
  path +
  "\n@@\n-" +
  before_text +
  "\n+" +
  after_text +
  "\n```"
}

///|
fn build_suggestions(
  snapshot : AlignSnapshot,
  direction : String,
) -> Array[AlignSuggestion] {
  let suggestions : Array[AlignSuggestion] = []
  for item in snapshot.diff_items {
    match item.category {
      "SPEC_ONLY" =>
        if direction != "impl-wins" {
          suggestions.push({
            category: item.category,
            direction: "spec-wins",
            title: "Implement " +
            item.requirement_title.unwrap_or("requirement"),
            summary: "Create implementation coverage for the unmatched requirement.",
            spec_file: item.spec_file,
            impl_file: None,
            patch: None,
            task: Some(
              "Implement `" +
              item.requirement_id.unwrap_or("requirement") +
              "` and verify its acceptance criteria.",
            ),
            reasons: item.reasons.copy(),
          })
        }
      "IMPL_ONLY" =>
        if direction != "spec-wins" {
          let implementation_name = item.implementation_name.unwrap_or(
            "implementation",
          )
          suggestions.push({
            category: item.category,
            direction: "impl-wins",
            title: "Document " + implementation_name,
            summary: "Add spec coverage for implementation that currently has no requirement match.",
            spec_file: None,
            impl_file: item.impl_file,
            patch: Some(
              "## ADDED Requirements\n\n### Requirement: " +
              implementation_name +
              "\nDescribe the expected behavior for `" +
              implementation_name +
              "`.\n",
            ),
            task: Some(
              "Add a requirement or scenario for `" + implementation_name + "`.",
            ),
            reasons: item.reasons.copy(),
          })
        }
      "DRIFTED" | "CONFLICT" => {
        let spec_patch = match
          (item.spec_file, item.spec_excerpt, item.impl_excerpt) {
          (Some(path), Some(spec_excerpt), Some(impl_excerpt)) =>
            match
              (
                first_numeric(Some(spec_excerpt)),
                first_numeric(Some(impl_excerpt)),
              ) {
              (Some(spec_value), Some(impl_value)) =>
                Some(
                  make_numeric_patch(path, spec_excerpt, spec_value, impl_value),
                )
              _ => None
            }
          _ => None
        }
        let impl_patch = match
          (item.impl_file, item.impl_excerpt, item.spec_excerpt) {
          (Some(path), Some(impl_excerpt), Some(spec_excerpt)) =>
            match
              (
                first_numeric(Some(impl_excerpt)),
                first_numeric(Some(spec_excerpt)),
              ) {
              (Some(impl_value), Some(spec_value)) =>
                Some(
                  make_numeric_patch(path, impl_excerpt, impl_value, spec_value),
                )
              _ => None
            }
          _ => None
        }
        if direction != "impl-wins" {
          suggestions.push({
            category: item.category,
            direction: "spec-wins",
            title: "Align implementation with " +
            item.requirement_id.unwrap_or("requirement"),
            summary: "Implementation appears to have drifted from the current spec.",
            spec_file: item.spec_file,
            impl_file: item.impl_file,
            patch: impl_patch,
            task: Some(
              "Update implementation to satisfy `" +
              item.requirement_id.unwrap_or("requirement") +
              "` and rerun `indexion spec align diff`.",
            ),
            reasons: item.reasons.copy(),
          })
        }
        if direction != "spec-wins" {
          suggestions.push({
            category: item.category,
            direction: "impl-wins",
            title: "Update spec for " +
            item.implementation_name.unwrap_or("implementation"),
            summary: "Specification appears outdated relative to the implementation.",
            spec_file: item.spec_file,
            impl_file: item.impl_file,
            patch: spec_patch,
            task: Some(
              "Revise the requirement or scenario text to reflect the implemented behavior.",
            ),
            reasons: item.reasons.copy(),
          })
        }
      }
      _ => ()
    }
  }
  suggestions
}

///|
fn build_suggest_report(snapshot : AlignSnapshot) -> AlignSuggestReport {
  {
    version: snapshot.version,
    generated_at: snapshot.generated_at,
    config: snapshot.config,
    summary: snapshot.summary,
    suggestions: build_suggestions(snapshot, snapshot.config.direction),
    used_specs: snapshot.used_specs,
    source_fingerprint: snapshot.source_fingerprint,
    commit: snapshot.commit,
    cache_hit: snapshot.cache_hit,
  }
}

///|
fn should_fail(summary : AlignSummary, fail_on : String) -> Bool {
  match fail_on {
    "drifted" => summary.drifted > 0 || summary.conflict > 0
    "spec-only" => summary.spec_only > 0
    "any" =>
      summary.drifted > 0 ||
      summary.spec_only > 0 ||
      summary.impl_only > 0 ||
      summary.conflict > 0
    _ => false
  }
}

///|
fn build_status_report(snapshot : AlignSnapshot) -> AlignStatusReport {
  let should_fail_now = should_fail(snapshot.summary, snapshot.config.fail_on)
  {
    version: snapshot.version,
    generated_at: snapshot.generated_at,
    config: snapshot.config,
    summary: snapshot.summary,
    status: if should_fail_now {
      "fail"
    } else {
      "pass"
    },
    fail_on: snapshot.config.fail_on,
    should_fail: should_fail_now,
    used_specs: snapshot.used_specs,
    source_fingerprint: snapshot.source_fingerprint,
    commit: snapshot.commit,
    cache_hit: snapshot.cache_hit,
  }
}

///|
fn resolve_input_path(path : String) -> String {
  if @config.is_absolute_path(path) {
    @config.normalize_path(path)
  } else {
    match @env.current_dir() {
      Some(cwd) => @config.join_path(cwd, path)
      None => @config.normalize_path(path)
    }
  }
}

///|
fn path_within_dir(root : String, path : String) -> Bool {
  let normalized_root = @config.normalize_path(root)
  let normalized_path = @config.normalize_path(path)
  normalized_path == normalized_root ||
  normalized_path.has_prefix(normalized_root + "/")
}

///|
async fn git_repo_root(anchor : String) -> String? {
  let root_arg = if path_is_dir(anchor) {
    anchor
  } else {
    @config.dirname(anchor)
  }
  @git.repo_root(root_arg)
}

///|
async fn current_commit_info(config : SpecAlignConfig) -> AlignCommitInfo? {
  let anchor = if config.impl_path.length() > 0 {
    config.impl_path
  } else {
    config.spec_path
  }
  let repo_root = match git_repo_root(anchor) {
    Some(value) => value
    None => return None
  }
  let head = match @git.head_commit(repo_root) {
    Some(value) => value
    None => return None
  }
  let short_head = match @git.head_commit(repo_root, short=true) {
    Some(value) => value
    None => return None
  }
  let committed_at = @git.head_commit_seconds(repo_root)
  let dirty = @git.status_dirty(repo_root, ".")
  Some({ repo_root, head, short_head, committed_at, dirty })
}

///|
async fn git_changed_files(config : SpecAlignConfig) -> Array[String]? {
  let anchor = if config.impl_path.length() > 0 {
    config.impl_path
  } else {
    config.spec_path
  }
  let repo_root = match git_repo_root(anchor) {
    Some(value) => value
    None => {
      println("Error: incremental spec align requires a git repository.")
      return None
    }
  }
  let spec_abs = resolve_input_path(config.spec_path)
  let impl_abs = resolve_input_path(config.impl_path)
  if !path_within_dir(repo_root, spec_abs) ||
    !path_within_dir(repo_root, impl_abs) {
    println(
      "Error: incremental spec align paths must live inside the current git repository.",
    )
    return None
  }
  let changed_rel = match
    @git.changed_files(repo_root, config.git_base, [spec_abs, impl_abs]) {
    Some(value) => value
    None => {
      println(
        "Error: failed to collect incremental git diff from base `" +
        config.git_base +
        "`.",
      )
      return None
    }
  }
  let changed : Array[String] = []
  for rel in changed_rel {
    let trimmed = trim(rel)
    if trimmed.length() > 0 {
      changed.push(@config.join_path(repo_root, trimmed))
    }
  }
  changed.sort()
  Some(changed)
}

///|
fn file_is_changed(changed_files : Map[String, Bool], path : String?) -> Bool {
  match path {
    Some(value) => changed_files.contains(@config.normalize_path(value))
    None => false
  }
}

///|
fn filter_snapshot_for_incremental(
  snapshot : AlignSnapshot,
  changed_files : Array[String],
) -> AlignSnapshot {
  let changed : Map[String, Bool] = {}
  for path in changed_files {
    changed.set(@config.normalize_path(path), true)
  }
  let affected_requirements : Map[String, Bool] = {}
  let affected_implementations : Map[String, Bool] = {}
  let mut changed_any = false
  for item in snapshot.diff_items {
    let item_changed = file_is_changed(changed, item.spec_file) ||
      file_is_changed(changed, item.impl_file)
    if !item_changed {
      continue
    }
    changed_any = true
    match item.requirement_id {
      Some(requirement_id) => affected_requirements.set(requirement_id, true)
      None => ()
    }
    match item.implementation_id {
      Some(implementation_id) =>
        affected_implementations.set(implementation_id, true)
      None => ()
    }
  }
  let mut updated = true
  while updated {
    updated = false
    for edge in snapshot.trace_edges {
      if edge.status != "matched" {
        continue
      }
      let req_known = affected_requirements.contains(edge.requirement_id)
      let impl_known = affected_implementations.contains(edge.implementation_id)
      if req_known && !impl_known {
        affected_implementations.set(edge.implementation_id, true)
        updated = true
      }
      if impl_known && !req_known {
        affected_requirements.set(edge.requirement_id, true)
        updated = true
      }
    }
  }
  let requirements = snapshot.requirements.filter(fn(req) {
    affected_requirements.contains(req.id)
  })
  let implementations = snapshot.implementations.filter(fn(node) {
    affected_implementations.contains(node.id)
  })
  let edges = snapshot.trace_edges.filter(fn(edge) {
    affected_requirements.contains(edge.requirement_id) ||
    affected_implementations.contains(edge.implementation_id)
  })
  let items = snapshot.diff_items.filter(fn(item) {
    match (item.requirement_id, item.implementation_id) {
      (Some(requirement_id), Some(implementation_id)) =>
        affected_requirements.contains(requirement_id) ||
        affected_implementations.contains(implementation_id)
      (Some(requirement_id), None) =>
        affected_requirements.contains(requirement_id)
      (None, Some(implementation_id)) =>
        affected_implementations.contains(implementation_id)
      _ => false
    }
  })
  let summary = if changed_any {
    build_summary(requirements, implementations, edges, items)
  } else {
    {
      matched: 0,
      drifted: 0,
      spec_only: 0,
      impl_only: 0,
      conflict: 0,
      total_requirements: 0,
      total_implementations: 0,
      total_edges: 0,
    }
  }
  {
    ..snapshot,
    requirements,
    implementations,
    trace_edges: edges,
    diff_items: items,
    summary,
  }
}

///|
async fn snapshot_for_config_async(config : SpecAlignConfig) -> AlignSnapshot? {
  let cache_dir = match resolve_cache_dir(config) {
    Some(value) => value
    None => return None
  }
  let effective_config = { ..config, cache_dir, }
  let previous = load_snapshot(cache_dir)
  let snapshot = match build_snapshot(effective_config, previous) {
    Some(value) => value
    None => return None
  }
  let snapshot = { ..snapshot, commit: current_commit_info(effective_config) }
  if !save_snapshot(cache_dir, snapshot) {
    return None
  }
  let snapshot = match load_snapshot(cache_dir) {
    Some(value) => value
    None => return None
  }
  if !config.incremental {
    return Some(snapshot)
  }
  let changed_files = match git_changed_files(config) {
    Some(value) => value
    None => return None
  }
  Some(filter_snapshot_for_incremental(snapshot, changed_files))
}

///|
pub async fn watch_probe_async(config : SpecAlignConfig) -> String? {
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dir=config.impl_path,
  )
  let spec_files = discover_spec_files(config.spec_path, registry)
  let impl_files = discover_impl_files(config.impl_path, registry)
  if spec_files.length() == 0 && impl_files.length() == 0 {
    return None
  }
  let parts : Array[String] = []
  for path in spec_files {
    parts.push(path)
    match @git.file_mtime_seconds(path) {
      Some(value) => parts.push(value.to_string())
      None => parts.push("")
    }
  }
  for path in impl_files {
    parts.push(path)
    match @git.file_mtime_seconds(path) {
      Some(value) => parts.push(value.to_string())
      None => parts.push("")
    }
  }
  Some(@cas_hash.compute_hash(parts.join("\u0001")).to_string())
}

///|
pub async fn diff_report_async(config : SpecAlignConfig) -> AlignDiffReport? {
  match snapshot_for_config_async(config) {
    Some(snapshot) => Some(build_diff_report(snapshot))
    None => None
  }
}

///|
pub async fn trace_report_async(config : SpecAlignConfig) -> AlignTraceReport? {
  match snapshot_for_config_async(config) {
    Some(snapshot) => Some(build_trace_report(snapshot))
    None => None
  }
}

///|
pub async fn suggest_report_async(
  config : SpecAlignConfig,
) -> AlignSuggestReport? {
  match snapshot_for_config_async(config) {
    Some(snapshot) => Some(build_suggest_report(snapshot))
    None => None
  }
}

///|
pub async fn status_report_async(
  config : SpecAlignConfig,
) -> AlignStatusReport? {
  match snapshot_for_config_async(config) {
    Some(snapshot) => Some(build_status_report(snapshot))
    None => None
  }
}
