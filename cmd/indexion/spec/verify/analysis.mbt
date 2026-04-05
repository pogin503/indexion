///|
/// Spec-to-implementation conformance analysis using TF-IDF vocabulary comparison.
///
/// Approach: tokenize both spec documents and implementation files using KGF,
/// build TF-IDF vectors, compute cosine distance, and extract gap terms
/// (terms present in spec but absent from implementation). Gap terms represent
/// specification concepts that may be missing from the implementation.
///
/// This is the reverse of reconcile's vocabulary divergence (which finds
/// code terms missing from docs). Here we find spec terms missing from code.

///|
/// Run the full analysis pipeline. Returns the verify report.
fn run_analysis(config : VerifyConfig) -> VerifyReport {
  let registry = @kgf_features.load_registry_or_empty(
    specs_dir=config.specs_dir,
    target_dir=config.target_dir,
  )
  // Discover spec files
  let spec_paths = expand_spec_patterns(config.spec_patterns)
  if spec_paths.length() == 0 {
    return empty_report(config, spec_paths, [])
  }
  // Discover implementation files
  let kgf_ignore = registry.collect_ignore_patterns()
  let discover_opts = @pipeline.DiscoverOptions::new(
    kgf_ignore~,
    root_dir=config.target_dir,
  )
  let impl_paths = @pipeline.discover_files(
    [config.target_dir],
    discover_opts,
  )
  // Tokenize spec and impl files
  let spec_tokens = tokenize_file_set(spec_paths, registry)
  let impl_tokens = tokenize_file_set(impl_paths, registry)
  if spec_tokens.length() == 0 {
    return empty_report(config, spec_paths, impl_paths)
  }
  // Build document frequency across all files (both spec and impl)
  let all_file_tokens : Array[Array[String]] = []
  for t in spec_tokens {
    all_file_tokens.push(t)
  }
  for t in impl_tokens {
    all_file_tokens.push(t)
  }
  let project_df = @tfidf.build_document_frequency(all_file_tokens)
  let total_docs = all_file_tokens.length()
  // Flatten spec and impl tokens
  let spec_flat = flatten_tokens(spec_tokens)
  let impl_flat = flatten_tokens(impl_tokens)
  // Compute overall cosine distance between spec and impl vocabularies
  let cosine_dist = @tfidf.calculate_tfidf_distance_from_tokens(
    spec_flat, impl_flat,
  )
  // Extract gap terms: spec terms not found in implementation
  let local_df = @tfidf.build_document_frequency([spec_flat, impl_flat])
  let spec_vec = @tfidf.build_tfidf_vector(spec_flat, local_df, 2)
  let impl_tf = @tfidf.build_term_frequency(impl_flat)
  let ubiquity_threshold = total_docs / 3 + 1
  let gap_terms = extract_gap_terms(
    spec_vec, impl_tf, project_df, ubiquity_threshold,
  )
  // Apply focus filter
  let filtered_gaps = apply_focus(gap_terms, config.focus)
  // Limit
  let limited_gaps = if filtered_gaps.length() > config.max_candidates {
    let result : Array[GapTerm] = []
    for i = 0; i < config.max_candidates; i = i + 1 {
      result.push(filtered_gaps[i])
    }
    result
  } else {
    filtered_gaps
  }
  // Convert to report items
  let items = gap_terms_to_items(limited_gaps, spec_paths)
  let summary = build_summary(items, cosine_dist)
  let used_specs = collect_used_specs(spec_paths, impl_paths, registry)
  {
    version: "spec-verify-v1",
    generated_at: 0,
    config: {
      spec_paths: spec_paths.copy(),
      target_dir: config.target_dir,
      focus: config.focus,
      max_candidates: config.max_candidates,
    },
    summary: {
      ..summary,
      spec_files: spec_paths.length(),
      impl_files: impl_paths.length(),
      spec_symbols: spec_flat.length(),
    },
    items,
    used_specs,
  }
}

///|
/// A term found in spec but absent from implementation.
struct GapTerm {
  term : String
  value : String
  weight : Double
  kind : String
} derive(Eq, Show)

///|
/// Tokenize a set of files individually, returning one token array per file.
/// Uses the same two-layer tokenization as reconcile's vocabulary analysis:
/// 1. KGF tokens → TF-IDF tokens (Kind:value for identifiers, Kind for syntax)
/// 2. Vocabulary sub-tokens: words from doc comments and string literals
fn tokenize_file_set(
  paths : Array[String],
  registry : @registry.KGFRegistry,
) -> Array[Array[String]] {
  let result : Array[Array[String]] = []
  for path in paths {
    let content = @fs.read_file_to_string(path) catch { _ => continue }
    let tokens = tokenize_single_file(content, path, registry)
    if tokens.length() > 0 {
      result.push(tokens)
    }
  }
  result
}

///|
/// Tokenize a single file into TF-IDF tokens using KGF.
///
/// Produces three layers of tokens for cross-format matching:
/// 1. Standard KGF TF-IDF tokens (Kind:value or Kind)
/// 2. Vocabulary sub-tokens from doc comments and text content (vocab:word)
/// 3. **Normalized tokens** (norm:word) — emitted for identifier tokens
///    (code) and reference tokens like INLINE_CODE (documents), enabling
///    spec documents and implementation code to share a vocabulary space.
fn tokenize_single_file(
  content : String,
  path : String,
  registry : @registry.KGFRegistry,
) -> Array[String] {
  let all_tokens : Array[String] = []
  let spec_name = registry.detect_from_path(path)
  match spec_name {
    Some(name) =>
      match registry.get_spec(name) {
        Some(spec) => {
          let id_set = @kgf_features.build_identifier_set(spec~)
          let vocab_set = @kgf_features.build_vocabulary_token_set(spec~)
          // reference_token_kinds: tokens in documents that reference code
          // identifiers (e.g., INLINE_CODE in markdown). We treat these as
          // identifier-like for norm: token generation.
          let ref_set = build_reference_token_set(spec)
          let lexer = @kgf_lexer.Lexer::new(spec.get_tokens())
          let tokens = lexer.tokenize(content)
          let mut in_code_fence = false
          // Track whether the current code fence contains implementation-like
          // code (vs. diagrams, pseudocode, etc.). Only emit norm: tokens from
          // fences whose language is a recognized programming/data language
          // with identifier_kinds in its KGF spec.
          let mut fence_has_identifiers = false
          for tok in tokens {
            let kind = tok.get_kind()
            // Track CODE_FENCE state for context-aware norm: emission.
            // CODE_FENCE text is like "```json" (open) or "```" (close).
            if kind == "CODE_FENCE" {
              if !(in_code_fence) {
                // Opening fence — extract language and check if it's a
                // known programming/data language.
                in_code_fence = true
                let fence_lang = extract_fence_language(
                  tok.get_text(),
                  registry,
                )
                fence_has_identifiers = fence_lang
              } else {
                // Closing fence
                in_code_fence = false
                fence_has_identifiers = false
              }
              continue
            }
            let tfidf_token = @kgf_features.kgf_tok_to_tfidf_token(
              tok, id_set~,
            )
            let lowered = tfidf_token.to_lower()
            if lowered.length() >= 2 {
              all_tokens.push(lowered)
            }
            let text = tok.get_text()
            // Emit norm: tokens for:
            // 1. Identifier tokens (code: struct fields, function names)
            // 2. Reference tokens (INLINE_CODE in documents)
            // 3. TEXT tokens inside CODE_FENCE blocks that contain
            //    implementation-like code (determined by fence language)
            let is_identifier_like = id_set.contains(kind) ||
              ref_set.contains(kind) ||
              (in_code_fence && fence_has_identifiers && kind == "TEXT")
            if is_identifier_like && text.length() >= 2 {
              let clean = strip_inline_code_markers(text)
              // For single-word tokens (identifiers, inline code), emit directly.
              // For multi-word tokens (TEXT lines inside code fences), split
              // into words first and emit norm: for each.
              if in_code_fence && kind == "TEXT" {
                sub_tokenize_as_norm(clean, all_tokens)
              } else {
                emit_normalized_tokens(clean.to_lower(), all_tokens)
              }
            }
            if vocab_set.contains(kind) {
              sub_tokenize_text(text, all_tokens)
            }
          }
        }
        None => ()
      }
    None => ()
  }
  all_tokens
}

///|
/// Build the set of reference token kinds from a KGF spec.
/// Reference tokens (e.g., INLINE_CODE) contain code identifiers within
/// documentation and should be treated as identifier-like for cross-format
/// vocabulary comparison.
fn build_reference_token_set(
  spec : @kgf_types.KGFSpec,
) -> Map[String, Bool] {
  let set : Map[String, Bool] = {}
  match spec.get_feature("reference_token_kinds") {
    Some(kinds) =>
      for kind in kinds {
        set[kind] = true
      }
    None => ()
  }
  set
}

///|
/// Extract the fence language from a CODE_FENCE token and check whether
/// it corresponds to a recognized language with identifier tokens.
/// Returns true if the fence language has a KGF spec with identifier_kinds
/// (meaning it's a programming or data language whose code examples contain
/// meaningful identifiers for vocabulary comparison).
///
/// "```json" → check if "json" has identifier_kinds → true
/// "```mermaid" → no KGF spec or no identifier_kinds → false
/// "```" → no language → false
fn extract_fence_language(
  fence_text : String,
  registry : @registry.KGFRegistry,
) -> Bool {
  // CODE_FENCE text starts with "```" followed by optional language name
  let mut start = 0
  while start < fence_text.length() && fence_text[start] == '`' {
    start += 1
  }
  if start >= fence_text.length() {
    // No language specified (bare "```")
    return false
  }
  let lang_name = fence_text[start:].to_string().to_lower()
  if lang_name.length() == 0 {
    return false
  }
  // Check if this language name maps to a KGF spec.
  // Try direct name match first, then extension-based lookup.
  let spec = match registry.get_spec(lang_name) {
    Some(s) => Some(s)
    None =>
      // Try as extension (e.g., "ts" → ".ts" → "typescript")
      match registry.get_lang_from_ext("." + lang_name) {
        Some(detected_lang) => registry.get_spec(detected_lang)
        None => None
      }
  }
  match spec {
    Some(s) => {
      // A spec with identifier_kinds is a programming/data language.
      let id_kinds = @kgf_features.build_identifier_set(spec=s)
      !(id_kinds.is_empty())
    }
    None => false
  }
}

///|
/// Strip inline code markers (backticks) from token text.
/// "`listChanged`" → "listChanged"
fn strip_inline_code_markers(text : String) -> String {
  let chars = text.to_array()
  let mut start = 0
  let mut end = chars.length()
  while start < end && chars[start] == '`' {
    start += 1
  }
  while end > start && chars[end - 1] == '`' {
    end -= 1
  }
  if start == 0 && end == chars.length() {
    return text
  }
  let result : Array[Char] = []
  for i = start; i < end; i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result)
}

///|
/// Emit normalized tokens for a value string.
/// Handles camelCase splitting: "listChanged" → "norm:listchanged", "norm:list", "norm:changed"
/// Handles snake_case splitting: "list_changed" → "norm:list_changed", "norm:list", "norm:changed"
fn emit_normalized_tokens(value : String, output : Array[String]) -> Unit {
  if value.length() < 2 {
    return
  }
  // Emit the full normalized form
  output.push("norm:" + value)
  // Split camelCase and snake_case into sub-words
  let parts = split_compound_identifier(value)
  for part in parts {
    if part.length() >= 3 {
      output.push("norm:" + part)
    }
  }
}

///|
/// Split text into words and emit norm: tokens for each.
/// Used for TEXT tokens inside CODE_FENCE blocks where content is code-like.
fn sub_tokenize_as_norm(text : String, output : Array[String]) -> Unit {
  let buf = StringBuilder::new()
  for ch in text {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' {
      buf.write_char(ch)
    } else {
      let word = buf.to_string().to_lower()
      if word.length() >= 2 {
        emit_normalized_tokens(word, output)
      }
      buf.reset()
    }
  }
  let last = buf.to_string().to_lower()
  if last.length() >= 2 {
    emit_normalized_tokens(last, output)
  }
}

///|
/// Split text content into individual lowercase words.
/// Emits vocab: tokens only. norm: tokens are reserved for identifiers
/// (from KGF identifier token kinds) to avoid polluting the normalized
/// vocabulary space with natural language words from documentation text.
fn sub_tokenize_text(text : String, output : Array[String]) -> Unit {
  let buf = StringBuilder::new()
  for ch in text {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' {
      buf.write_char(ch)
    } else {
      let word = buf.to_string().to_lower()
      if word.length() >= 3 {
        output.push("vocab:" + word)
      }
      buf.reset()
    }
  }
  let last = buf.to_string().to_lower()
  if last.length() >= 3 {
    output.push("vocab:" + last)
  }
}

///|
/// Split a compound identifier into sub-words.
/// Handles camelCase: "listChanged" → ["list", "changed"]
/// Handles snake_case: "list_changed" → ["list", "changed"]
/// Handles PascalCase: "JsonRpcRequest" → ["json", "rpc", "request"]
fn split_compound_identifier(s : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder::new()
  let chars = s.to_array()
  for i, ch in chars {
    if ch == '_' || ch == '-' {
      // Separator: flush current word
      let word = buf.to_string()
      if word.length() > 0 {
        parts.push(word)
      }
      buf.reset()
    } else if ch >= 'A' && ch <= 'Z' {
      // Uppercase: start new word (camelCase boundary)
      // But handle consecutive uppercase (e.g., "JSON" → one word)
      let next_is_lower = i + 1 < chars.length() && chars[i + 1] >= 'a' && chars[i + 1] <= 'z'
      let prev_is_lower = i > 0 && chars[i - 1] >= 'a' && chars[i - 1] <= 'z'
      if prev_is_lower || (buf.to_string().length() > 0 && next_is_lower) {
        let word = buf.to_string()
        if word.length() > 0 {
          parts.push(word)
        }
        buf.reset()
      }
      buf.write_char((ch.to_int() + 32).unsafe_to_char())
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
/// Flatten multiple token arrays into one.
fn flatten_tokens(arrays : Array[Array[String]]) -> Array[String] {
  let result : Array[String] = []
  for arr in arrays {
    for tok in arr {
      result.push(tok)
    }
  }
  result
}

///|
/// Extract gap terms: terms with high TF-IDF weight in spec that are
/// absent from implementation, filtered by project-wide document frequency
/// to suppress ubiquitous terms.
fn extract_gap_terms(
  spec_vec : @tfidf.TfidfVector,
  impl_tf : Map[String, Int],
  project_df : Map[String, Int],
  ubiquity_threshold : Int,
) -> Array[GapTerm] {
  // Build a set of values present in the implementation across all prefixes.
  // This enables cross-prefix matching: if impl has "norm:jsonrpc" or
  // "Ident:jsonrpc" or "vocab:jsonrpc", the value "jsonrpc" is considered
  // present. Without this, "vocab:jsonrpc" from spec and "norm:jsonrpc"
  // from impl would be treated as different terms.
  let impl_values : Map[String, Bool] = {}
  for kv in impl_tf {
    let value = extract_token_value(kv.0)
    if value.length() >= 2 {
      impl_values[value] = true
    }
  }
  let value_weights : Map[String, (Double, String)] = {}
  for entry in spec_vec.iter() {
    let term = entry.0
    let weight = entry.1
    // Only consider normalized (norm:) and vocabulary (vocab:) tokens.
    if !(is_content_token(term)) {
      continue
    }
    // Must be a meaningful term (has a value part after ':')
    let value = extract_token_value(term)
    if value.length() < 2 {
      continue
    }
    // Cross-prefix check: skip if the VALUE exists in impl under any prefix
    if impl_values.contains(value) {
      continue
    }
    // Also skip if the exact term exists in impl
    if impl_tf.get(term).unwrap_or(0) > 0 {
      continue
    }
    // Filter ubiquitous terms
    let freq = project_df.get(term).unwrap_or(0)
    if freq >= ubiquity_threshold {
      continue
    }
    // Skip pure numeric values (including negative numbers like error codes)
    if is_numeric_value(value) {
      continue
    }
    let kind = extract_token_kind(term)
    match value_weights.get(value) {
      Some((existing_weight, _existing_kind)) =>
        if weight > existing_weight {
          value_weights[value] = (weight, kind)
        }
      None => value_weights[value] = (weight, kind)
    }
  }
  let gaps : Array[GapTerm] = []
  for vw in value_weights {
    let value = vw.0
    let (weight, kind) = vw.1
    gaps.push({ term: kind + ":" + value, value, weight, kind })
  }
  // Sort by weight descending
  gaps.sort_by(fn(a, b) { b.weight.compare(a.weight) })
  // Apply Otsu thresholding to separate meaningful gaps from noise
  if gaps.length() <= 1 {
    return gaps
  }
  let weights : Array[Double] = gaps.map(fn(g) { g.weight })
  let cutoff = kneedle_threshold_index(weights)
  let limit = if cutoff < gaps.length() { cutoff } else { gaps.length() }
  if limit == 0 {
    return []
  }
  let result : Array[GapTerm] = []
  for i = 0; i < limit; i = i + 1 {
    result.push(gaps[i])
  }
  result
}

///|
/// Extract the value part from a TF-IDF token.
/// "Ident:config" → "config", "vocab:template" → "template"
fn extract_token_value(token : String) -> String {
  for i = 0; i < token.length(); i = i + 1 {
    if token[i] == ':' && i < token.length() - 1 {
      return token[i + 1:].to_string()
    }
  }
  token
}

///|
/// Extract the kind part from a TF-IDF token.
/// "Ident:config" → "Ident", "vocab:template" → "vocab"
fn extract_token_kind(token : String) -> String {
  for i = 0; i < token.length(); i = i + 1 {
    if token[i] == ':' {
      return token[:i].to_string()
    }
  }
  token
}

///|
/// Check if a token is a content token suitable for gap term detection.
/// Only norm: tokens are considered. These are generated from:
/// - Identifier tokens in code files (struct fields, function names)
/// - Reference tokens (INLINE_CODE) in documents
/// - TEXT tokens inside CODE_FENCE blocks in documents (code examples)
fn is_content_token(term : String) -> Bool {
  has_prefix(term, "norm:")
}

///|
fn has_prefix(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() {
    return false
  }
  s[:prefix.length()] == prefix
}

///|
/// Check if a string is a pure numeric value (digits, optionally with leading
/// minus sign). These are not meaningful vocabulary terms.
fn is_numeric_value(s : String) -> Bool {
  if s.length() == 0 {
    return true
  }
  let mut start = 0
  if s[0] == '-' {
    start = 1
  }
  if start >= s.length() {
    return false
  }
  for i = start; i < s.length(); i = i + 1 {
    let c = s[i]
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
/// Kneedle algorithm for finding the elbow (knee) point in a descending-sorted
/// weight curve. Returns the number of items before the knee — i.e., the count
/// of "significant" items.
///
/// For a decreasing curve, the knee is the point that deviates most below
/// the straight line connecting the first and last points. This corresponds
/// to the sharpest transition from "high-weight signal" to "low-weight noise."
///
/// Reference: Satopaa et al., "Finding a 'Kneedle' in a Haystack", 2011.
fn kneedle_threshold_index(weights : Array[Double]) -> Int {
  let n = weights.length()
  if n <= 1 {
    return n
  }
  if n == 2 {
    // Two items: keep both if weights are close, otherwise keep only the first.
    let ratio = if weights[0] > 0.0 { weights[1] / weights[0] } else { 1.0 }
    return if ratio > 0.5 { 2 } else { 1 }
  }
  // Step 1: Normalize x to [0, 1] and y to [0, 1].
  let x_max = (n - 1).to_double()
  let y_min = weights[n - 1]
  let y_max = weights[0]
  let y_range = y_max - y_min
  if y_range <= 0.0 {
    // All weights are equal — no knee, keep all.
    return n
  }
  // Step 2: Compute D_n = y_norm - y_line for each point.
  // y_line is the value on the straight line from (0, 1) to (1, 0).
  // For a decreasing curve, the knee is where D_n is most negative
  // (the curve drops farthest below the diagonal).
  let mut best_idx = 0
  let mut best_dn = 0.0
  for i = 0; i < n; i = i + 1 {
    let x_norm = i.to_double() / x_max
    let y_norm = (weights[i] - y_min) / y_range
    let y_line = 1.0 - x_norm
    let dn = y_norm - y_line
    if dn < best_dn {
      best_dn = dn
      best_idx = i
    }
  }
  // The knee point itself is where the curve has already "bent."
  // We want items BEFORE the knee (the significant ones).
  // The knee index is the first point in the noise region.
  if best_idx < 1 { 1 } else { best_idx }
}

///|
/// Apply focus filter to gap terms.
fn apply_focus(gaps : Array[GapTerm], focus : String) -> Array[GapTerm] {
  if focus == "all" {
    return gaps
  }
  gaps.filter(fn(g) { g.kind == focus })
}

///|
/// Convert gap terms to VerifyItems for the report.
fn gap_terms_to_items(
  gaps : Array[GapTerm],
  _spec_paths : Array[String],
) -> Array[VerifyItem] {
  gaps.map(
    fn(g) {
      {
        status: "missing",
        spec_symbol: {
          identifier: g.value,
          kind: g.kind,
          context: "",
          source_path: "",
          source_line: 0,
        },
        evidence: {
          found_in: [],
          match_kind: "",
          note: "spec term not found in implementation (weight: " +
            format_weight(g.weight) +
            ")",
        },
      }
    },
  )
}

///|
fn format_weight(w : Double) -> String {
  let scaled = w * 10000.0
  let int_part = scaled.to_int()
  let major = int_part / 100
  let minor = int_part % 100
  major.to_string() +
  "." +
  (if minor < 10 { "0" } else { "" }) +
  minor.to_string() +
  "e-2"
}

///|
/// Build summary from items and cosine distance.
fn build_summary(items : Array[VerifyItem], cosine_dist : Double) -> VerifySummary {
  let mut missing = 0
  let mut dead = 0
  let mut drift = 0
  for item in items {
    match item.status {
      "missing" => missing += 1
      "dead" => dead += 1
      "drift" => drift += 1
      _ => ()
    }
  }
  {
    spec_files: 0,
    spec_symbols: 0,
    impl_files: 0,
    cosine_distance: cosine_dist,
    gap_count: missing,
    matched: 0,
    missing,
    dead,
    drift,
  }
}

///|
/// Expand glob patterns into deduplicated file paths.
fn expand_spec_patterns(patterns : Array[String]) -> Array[String] {
  let result : Array[String] = []
  let seen : Map[String, Bool] = {}
  for pattern in patterns {
    let paths = @glob.expand_glob(pattern)
    for path in paths {
      if !(seen.contains(path)) {
        seen[path] = true
        result.push(path)
      }
    }
  }
  result
}

///|
/// Collect KGF spec names used for the given file paths.
fn collect_used_specs(
  spec_paths : Array[String],
  impl_paths : Array[String],
  registry : @registry.KGFRegistry,
) -> Array[String] {
  let seen : Map[String, Bool] = {}
  let result : Array[String] = []
  let all_paths = spec_paths + impl_paths
  for path in all_paths {
    match registry.detect_from_path(path) {
      Some(lang) =>
        if !(seen.contains(lang)) {
          seen[lang] = true
          result.push(lang)
        }
      None => ()
    }
  }
  result
}

///|
fn empty_report(
  config : VerifyConfig,
  spec_paths : Array[String],
  impl_paths : Array[String],
) -> VerifyReport {
  {
    version: "spec-verify-v1",
    generated_at: 0,
    config: {
      spec_paths: spec_paths.copy(),
      target_dir: config.target_dir,
      focus: config.focus,
      max_candidates: config.max_candidates,
    },
    summary: {
      spec_files: spec_paths.length(),
      spec_symbols: 0,
      impl_files: impl_paths.length(),
      cosine_distance: 0.0,
      gap_count: 0,
      matched: 0,
      missing: 0,
      dead: 0,
      drift: 0,
    },
    items: [],
    used_specs: [],
  }
}
