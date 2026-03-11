///|
priv struct ModuleSignals {
  tokens : Map[String, Bool]
  anchors : Map[String, Bool]
}

///|
priv struct CandidateBuildResult {
  candidates : Array[ReconcileCandidate]
  module_covered_symbols : Int
}

///|
priv struct FragmentMatchSignals {
  exact_tokens : Map[String, Bool]
  reference_tokens : Map[String, Bool]
}

///|
fn is_ascii_upper(ch : Char) -> Bool {
  ch >= 'A' && ch <= 'Z'
}

///|
fn is_ascii_lower(ch : Char) -> Bool {
  ch >= 'a' && ch <= 'z'
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn is_token_separator(ch : Char) -> Bool {
  ch == '_' || ch == '-' || ch == '.' || ch == '/' || ch == ':'
}

///|
fn is_token_char(ch : Char) -> Bool {
  is_ascii_upper(ch) ||
  is_ascii_lower(ch) ||
  is_ascii_digit(ch) ||
  is_token_separator(ch)
}

///|
fn is_all_digits(text : String) -> Bool {
  let chars = text.to_array()
  if chars.length() == 0 {
    return false
  }
  for ch in chars {
    if not(is_ascii_digit(ch)) {
      return false
    }
  }
  true
}

///|
fn is_specific_token(token : String) -> Bool {
  let normalized = lower_string(token)
  if normalized.length() < 2 || is_all_digits(normalized) {
    return false
  }
  if normalized == "db" ||
    normalized == "md" ||
    normalized == "kgf" ||
    normalized == "json" ||
    normalized == "toml" {
    return true
  }
  normalized.length() >= 5 ||
  normalized.contains("_") ||
  normalized.contains("-") ||
  normalized.contains(".")
}

///|
fn add_specific_token(tokens : Map[String, Bool], token : String) -> Unit {
  let normalized = lower_string(trim_string(token))
  if not(is_specific_token(normalized)) {
    return
  }
  tokens.set(normalized, true)
  if normalized.has_suffix("s") && normalized.length() >= 5 {
    let singular = substring(normalized, 0, normalized.length() - 1)
    if is_specific_token(singular) {
      tokens.set(singular, true)
    }
  }
}

///|
fn build_exact_token_index(text : String) -> Map[String, Bool] {
  let index : Map[String, Bool] = {}
  let raw_token : Array[Char] = []
  fn flush_raw(index : Map[String, Bool], raw_token : Array[Char]) -> Unit {
    if raw_token.length() == 0 {
      return
    }
    let raw = lower_string(String::from_array(raw_token))
    raw_token.clear()
    if raw.length() > 0 {
      index.set(raw, true)
    }
  }
  for ch in text.to_array() {
    if is_token_char(ch) {
      raw_token.push(ch)
    } else {
      flush_raw(index, raw_token)
    }
  }
  flush_raw(index, raw_token)
  index
}

///|
fn normalize_feature_token_text(text : String) -> String {
  let chars = text.to_array()
  if chars.length() >= 2 {
    let first = chars[0]
    let last = chars[chars.length() - 1]
    if (first == '`' && last == '`') ||
      (first == '"' && last == '"') ||
      (first == '\'' && last == '\'') ||
      (first == '[' && last == ']') ||
      (first == '(' && last == ')') ||
      (first == '{' && last == '}') {
      return substring(text, 1, text.length() - 1)
    }
  }
  text
}

///|
fn add_surface_term(tokens : Map[String, Bool], text : String) -> Unit {
  let normalized = normalize_feature_token_text(text)
  let raw_tokens = build_exact_token_index(normalized)
  for entry in raw_tokens {
    add_specific_token(tokens, entry.0)
    let part : Array[Char] = []
    fn flush_part(tokens : Map[String, Bool], part : Array[Char]) -> Unit {
      if part.length() == 0 {
        return
      }
      let raw = String::from_array(part)
      part.clear()
      add_specific_token(tokens, raw)
    }
    for ch in entry.0.to_array() {
      if is_token_separator(ch) {
        flush_part(tokens, part)
      } else {
        part.push(ch)
      }
    }
    flush_part(tokens, part)
  }
}

///|
fn file_stem(path : String) -> String {
  let base = @config_paths.basename(path)
  let ext = @config_paths.extension(path)
  if ext.length() > 0 && base.has_suffix(ext) {
    substring(base, 0, base.length() - ext.length())
  } else {
    base
  }
}

///|
fn build_feature_token_kinds(
  spec : @kgf_types.KGFSpec,
  feature_name : String,
) -> Map[String, Bool] {
  let kinds : Map[String, Bool] = {}
  match spec.get_feature(feature_name) {
    Some(values) =>
      for value in values {
        let normalized = lower_string(trim_string(value))
        if normalized.length() > 0 {
          kinds.set(normalized, true)
        }
      }
    None => ()
  }
  kinds
}

///|
fn add_feature_terms(
  tokens : Map[String, Bool],
  text : String,
  spec : @kgf_types.KGFSpec,
  feature_name : String,
) -> Bool {
  let selected_kinds = build_feature_token_kinds(spec, feature_name)
  if selected_kinds.is_empty() {
    return false
  }
  let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
  let lexed = lexer.tokenize(text)
  for tok in lexed {
    if selected_kinds.contains(lower_string(tok.get_kind())) {
      add_surface_term(tokens, tok.get_text())
    }
  }
  true
}

///|
fn add_path_anchor_terms(tokens : Map[String, Bool], text : String) -> Unit {
  add_surface_term(tokens, text)
}

///|
fn build_module_signals(
  units : Array[CodeUnit],
  registry : @registry.KGFRegistry,
) -> Map[String, ModuleSignals] {
  let signals : Map[String, ModuleSignals] = {}
  for unit in units {
    let current = match signals.get(unit.module_path) {
      Some(existing) => existing
      None => {
        let seeded = { tokens: {}, anchors: {} }
        add_path_anchor_terms(seeded.anchors, file_stem(unit.module_path))
        add_path_anchor_terms(seeded.tokens, unit.module_path)
        add_path_anchor_terms(seeded.tokens, file_stem(unit.module_path))
        let content = @fs.read_file_to_string(unit.module_path) catch {
          _ => ""
        }
        if content.length() > 0 {
          match registry.detect_from_path(unit.module_path) {
            Some(lang) =>
              match registry.get_spec(lang) {
                Some(spec) =>
                  if not(
                      add_feature_terms(
                        seeded.tokens,
                        content,
                        spec,
                        "coverage_token_kinds",
                      ),
                    ) {
                    add_surface_term(seeded.tokens, content)
                  }
                None => add_surface_term(seeded.tokens, content)
              }
            None => add_surface_term(seeded.tokens, content)
          }
        }
        seeded
      }
    }
    add_surface_term(current.tokens, unit.name)
    add_surface_term(current.tokens, unit.ns)
    add_path_anchor_terms(current.tokens, unit.module_id)
    signals.set(unit.module_path, current)
  }
  signals
}

///|
fn build_fragment_terms(
  fragments : Array[DocFragment],
  registry : @registry.KGFRegistry,
) -> Map[String, Map[String, Bool]] {
  let terms : Map[String, Map[String, Bool]] = {}
  for fragment in fragments {
    let current : Map[String, Bool] = {}
    let source_text = fragment.title + "\n" + fragment.content
    match registry.get_spec(fragment.spec) {
      Some(spec) =>
        if not(
            add_feature_terms(
              current, source_text, spec, "coverage_token_kinds",
            ),
          ) {
          add_surface_term(current, source_text)
        }
      None => add_surface_term(current, source_text)
    }
    terms.set(fragment.id, current)
  }
  terms
}

///|
fn terms_overlap(left : String, right : String) -> Bool {
  if left == right {
    return true
  }
  let (shorter, longer) = if left.length() <= right.length() {
    (left, right)
  } else {
    (right, left)
  }
  shorter.length() >= 6 && longer.contains(shorter)
}

///|
fn shared_terms(
  left : Map[String, Bool],
  right : Map[String, Bool],
) -> Array[String] {
  let shared : Array[String] = []
  for left_entry in left {
    for right_entry in right {
      if terms_overlap(left_entry.0, right_entry.0) {
        shared.push(left_entry.0)
        break
      }
    }
  }
  shared.sort()
  shared
}

///|
fn build_module_coverage_index(
  units : Array[CodeUnit],
  fragments : Array[DocFragment],
  registry : @registry.KGFRegistry,
) -> Map[String, Bool] {
  let module_signals = build_module_signals(units, registry)
  let fragment_terms = build_fragment_terms(fragments, registry)
  let coverage : Map[String, Bool] = {}
  for module_entry in module_signals {
    let signals = module_entry.1
    let mut covered = false
    for fragment in fragments {
      let terms = match fragment_terms.get(fragment.id) {
        Some(value) => value
        None => continue
      }
      let overlaps = shared_terms(signals.tokens, terms)
      if overlaps.length() < 2 {
        continue
      }
      let anchor_hits = shared_terms(signals.anchors, terms)
      if anchor_hits.length() > 0 || overlaps.length() >= 4 {
        covered = true
        break
      }
    }
    if covered {
      coverage.set(module_entry.0, true)
    }
  }
  coverage
}

///|
fn contains_term(text : String, term : String) -> Bool {
  let normalized_text = lower_string(text)
  let normalized_term = lower_string(term)
  normalized_text.contains(normalized_term)
}

///|
fn build_fragment_match_signals(
  fragments : Array[DocFragment],
  registry : @registry.KGFRegistry,
) -> Map[String, FragmentMatchSignals] {
  let signals : Map[String, FragmentMatchSignals] = {}
  for fragment in fragments {
    let source_text = fragment.title + "\n" + fragment.content
    let exact_tokens = build_exact_token_index(source_text)
    let reference_tokens : Map[String, Bool] = {}
    match registry.get_spec(fragment.spec) {
      Some(spec) => {
        let reference_kinds = build_feature_token_kinds(
          spec, "reference_token_kinds",
        )
        if reference_kinds.is_empty() {
          signals.set(fragment.id, { exact_tokens, reference_tokens })
          continue
        }
        let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
        let tokens = lexer.tokenize(source_text)
        for tok in tokens {
          let normalized_kind = lower_string(tok.get_kind())
          if reference_kinds.contains(normalized_kind) {
            let normalized = normalize_feature_token_text(tok.get_text())
            let token_index = build_exact_token_index(normalized)
            for entry in token_index {
              reference_tokens.set(entry.0, true)
            }
          }
        }
      }
      None => ()
    }
    signals.set(fragment.id, { exact_tokens, reference_tokens })
  }
  signals
}

///|
fn match_fragment(
  unit : CodeUnit,
  fragment : DocFragment,
  signals : FragmentMatchSignals,
  allow_file_fallback : Bool,
) -> (Int, String, Array[String]) {
  let source_text = fragment.title + "\n" + fragment.content
  let text = lower_string(source_text)
  let matched : Array[String] = []
  let qualified_dot = unit.ns + "." + unit.name
  let qualified_colon = unit.ns + "::" + unit.name
  if unit.ns.length() > 0 && contains_term(text, qualified_dot) {
    matched.push(qualified_dot)
    return (100, "qualified_symbol", matched)
  }
  if unit.ns.length() > 0 && contains_term(text, qualified_colon) {
    matched.push(qualified_colon)
    return (95, "qualified_symbol", matched)
  }
  if contains_term(text, "`" + lower_string(unit.name) + "`") {
    matched.push(unit.name)
    return (92, "inline_symbol", matched)
  }
  if signals.reference_tokens.contains(lower_string(unit.name)) {
    matched.push(unit.name)
    return (85, "symbol_name", matched)
  }
  if allow_file_fallback {
    let base = @config_paths.basename(unit.module_path)
    if base.length() > 0 && signals.exact_tokens.contains(lower_string(base)) {
      matched.push(base)
      return (45, "file_name", matched)
    }
  }
  (0, "none", matched)
}

///|
fn build_code_anchor(unit : CodeUnit) -> CodeAnchor {
  {
    symbol_id: unit.symbol_id,
    name: unit.name,
    kind: unit.kind,
    ns: unit.ns,
    module_path: unit.module_path,
    inline_doc: unit.inline_doc,
  }
}

///|
fn build_doc_anchor(fragment : DocFragment) -> DocAnchor {
  {
    fragment_id: fragment.id,
    path: fragment.path,
    spec: fragment.spec,
    kind: fragment.kind,
    title: fragment.title,
    preview: fragment.preview,
  }
}

///|
fn timestamp_for_path(
  root : String,
  path : String,
  config : ReconcileConfig,
) -> TimestampInfo {
  let repo_ok = config.git_preferred && @git.is_repo(root)
  if repo_ok {
    let git_time = @git.last_commit_seconds(root, path)
    let dirty = @git.status_dirty(root, path)
    if dirty {
      if config.mtime_fallback {
        match @git.file_mtime_seconds(path) {
          Some(seconds) =>
            return {
              epoch_seconds: Some(seconds),
              source: "mtime",
              is_dirty: true,
            }
          None => ()
        }
      }
    } else {
      match git_time {
        Some(seconds) =>
          return {
            epoch_seconds: Some(seconds),
            source: "git",
            is_dirty: false,
          }
        None => ()
      }
    }
  }
  if config.mtime_fallback {
    match @git.file_mtime_seconds(path) {
      Some(seconds) =>
        return {
          epoch_seconds: Some(seconds),
          source: "mtime",
          is_dirty: false,
        }
      None => ()
    }
  }
  TimestampInfo::unknown()
}

///|
fn time_relation(
  code_time : TimestampInfo,
  doc_time : TimestampInfo,
  threshold_seconds : Int,
) -> String {
  match (code_time.epoch_seconds, doc_time.epoch_seconds) {
    (Some(code_seconds), Some(doc_seconds)) => {
      let diff = code_seconds - doc_seconds
      if diff.abs() <= threshold_seconds {
        "in_sync"
      } else if diff > 0 {
        "doc_older"
      } else {
        "doc_newer"
      }
    }
    _ => "unknown"
  }
}

///|
fn candidate_id(unit : CodeUnit, fragment : DocFragment?) -> String {
  let doc_key = match fragment {
    Some(value) => value.id
    None => "missing"
  }
  "cand:" + make_hash([unit.symbol_id, doc_key])
}

///|
fn build_candidates(
  units : Array[CodeUnit],
  fragments : Array[DocFragment],
  config : ReconcileConfig,
  registry : @registry.KGFRegistry,
) -> CandidateBuildResult {
  let candidates : Array[ReconcileCandidate] = []
  let module_coverage = build_module_coverage_index(units, fragments, registry)
  let fragment_signals = build_fragment_match_signals(fragments, registry)
  let mut module_covered_symbols = 0
  for unit in units {
    let matches : Array[(Int, String, Array[String], DocFragment)] = []
    for fragment in fragments {
      let signals = match fragment_signals.get(fragment.id) {
        Some(value) => value
        None => { exact_tokens: {}, reference_tokens: {} }
      }
      let (score, match_kind, matched_terms) = match_fragment(
        unit,
        fragment,
        signals,
        config.allow_file_fallback,
      )
      if score > 0 {
        matches.push((score, match_kind, matched_terms, fragment))
      }
    }
    matches.sort_by(fn(a, b) {
      let score_cmp = b.0.compare(a.0)
      if score_cmp != 0 {
        score_cmp
      } else {
        a.3.id.compare(b.3.id)
      }
    })
    let has_inline_doc = unit.inline_doc is Some(_)
    if matches.length() == 0 {
      if not(has_inline_doc) {
        if module_coverage.contains(unit.module_path) {
          module_covered_symbols += 1
        } else {
          let code_time = timestamp_for_path(
            config.target_dir,
            unit.module_path,
            config,
          )
          candidates.push({
            id: candidate_id(unit, None),
            symbol_id: unit.symbol_id,
            status: "missing_doc",
            time_relation: "unmatched",
            mapping_confidence: 0,
            recommended_action: "update_doc",
            mechanical_digest: "",
            code_anchor: build_code_anchor(unit),
            doc_anchor: None,
            evidence: {
              matched_terms: [],
              match_kind: "none",
              reason: "No external document fragment matched this symbol.",
              code_time,
              doc_time: TimestampInfo::unknown(),
            },
            logical_review_key: None,
            logical_review_status: "pending",
            logical_review_reused: false,
            needs_logical_review: true,
          })
        }
      }
      continue
    }
    let best = matches[0]
    let doc_time = timestamp_for_path(config.target_dir, best.3.path, config)
    let code_time = timestamp_for_path(
      config.target_dir,
      unit.module_path,
      config,
    )
    let relation = time_relation(code_time, doc_time, config.threshold_seconds)
    let (status, action) = match relation {
      "doc_older" => ("stale_doc", "update_doc")
      "doc_newer" => ("review_both", "review_both")
      _ =>
        if best.0 < 80 {
          ("review_mapping", "review_mapping")
        } else {
          ("in_sync", "")
        }
    }
    if status == "in_sync" {
      continue
    }
    let reason = match relation {
      "doc_older" =>
        "Implementation appears newer than the mapped document fragment."
      "doc_newer" =>
        "Document appears newer than the implementation and may be ahead of code."
      _ => "Mapping is heuristic and should be reviewed."
    }
    candidates.push({
      id: candidate_id(unit, Some(best.3)),
      symbol_id: unit.symbol_id,
      status,
      time_relation: relation,
      mapping_confidence: best.0,
      recommended_action: action,
      mechanical_digest: "",
      code_anchor: build_code_anchor(unit),
      doc_anchor: Some(build_doc_anchor(best.3)),
      evidence: {
        matched_terms: best.2,
        match_kind: best.1,
        reason,
        code_time,
        doc_time,
      },
      logical_review_key: None,
      logical_review_status: "pending",
      logical_review_reused: false,
      needs_logical_review: true,
    })
  }
  candidates.sort_by(fn(a, b) {
    let status_cmp = status_priority(a.status).compare(
      status_priority(b.status),
    )
    if status_cmp != 0 {
      status_cmp
    } else {
      b.mapping_confidence.compare(a.mapping_confidence)
    }
  })
  let limited = if candidates.length() <= config.max_candidates {
    candidates
  } else {
    let limited : Array[ReconcileCandidate] = []
    for i = 0; i < config.max_candidates; i = i + 1 {
      limited.push(candidates[i])
    }
    limited
  }
  { candidates: limited, module_covered_symbols }
}

///|
fn build_summary(
  units : Array[CodeUnit],
  fragments : Array[DocFragment],
  candidates : Array[ReconcileCandidate],
  module_covered_symbols : Int,
  logical_reviews : Array[LogicalReviewTask],
  reused_logical_reviews : Int,
) -> ReconcileSummary {
  let mut symbols_with_inline_doc = 0
  for unit in units {
    if unit.inline_doc is Some(_) {
      symbols_with_inline_doc += 1
    }
  }
  let mut missing_doc = 0
  let mut stale_doc = 0
  let mut review_mapping = 0
  let mut review_both = 0
  let mut pending_logical_reviews = 0
  let mut completed_logical_reviews = 0
  let mut new_logical_reviews = 0
  for task in logical_reviews {
    if task.reused {
      ()
    } else {
      new_logical_reviews += 1
    }
  }
  for candidate in candidates {
    match candidate.status {
      "missing_doc" => missing_doc += 1
      "stale_doc" => stale_doc += 1
      "review_both" => review_both += 1
      _ => review_mapping += 1
    }
    if candidate.logical_review_status == "pending" {
      pending_logical_reviews += 1
    } else if candidate.logical_review_status != "disabled" {
      completed_logical_reviews += 1
    }
  }
  {
    total_symbols: units.length(),
    symbols_with_inline_doc,
    module_covered_symbols,
    total_doc_fragments: fragments.length(),
    total_candidates: candidates.length(),
    missing_doc,
    stale_doc,
    review_mapping,
    review_both,
    pending_logical_reviews,
    new_logical_reviews,
    reused_logical_reviews,
    completed_logical_reviews,
  }
}
