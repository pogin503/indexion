///|
type AgentOrientItem = @types.AgentOrientItem

///|
type AgentOrientMap = @types.AgentOrientMap

///|
type LocalOwnerBrief = @types.LocalOwnerBrief

///|
fn task_tokens(text : String) -> Array[String] {
  @matching.task_tokens(text)
}

///|
fn task_token_stream(text : String) -> Array[String] {
  @matching.task_token_stream(text)
}

///|
fn matched_terms_in_tokens(
  task_terms : Array[String],
  text_terms : Array[String],
) -> Array[String] {
  @matching.matched_terms_in_tokens(task_terms, text_terms)
}

///|
fn role_is_documentation(role : String) -> Bool {
  @matching.role_is_documentation(role)
}

///|
fn is_documentation_path(path : String) -> Bool {
  @map.is_documentation_path(path)
}

///|
/// Score the best local window inside an owner summary for concentrated task
/// term matches.
pub fn focused_owner_window_score(
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
pub fn owner_focus_window_size() -> Int {
  80
}

///|
pub fn owner_focus_stride() -> Int {
  24
}
