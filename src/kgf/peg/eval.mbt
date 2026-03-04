///|
/// EvalResult represents the result of a PEG evaluation.
pub struct EvalResult {
  ok : Bool
  pos : Int
  labels : Map[String, Json]
  events : Array[(String, Map[String, Json])]
}

///|
/// Creates a new successful EvalResult.
pub fn EvalResult::success(
  pos : Int,
  labels? : Map[String, Json] = Map::new(),
  events? : Array[(String, Map[String, Json])] = [],
) -> EvalResult {
  { ok: true, pos, labels, events }
}

///|
/// Creates a new failed EvalResult.
pub fn EvalResult::failure(pos : Int) -> EvalResult {
  { ok: false, pos, labels: Map::new(), events: [] }
}

///|
/// Returns true if the evaluation succeeded.
pub fn EvalResult::is_ok(self : EvalResult) -> Bool {
  self.ok
}

///|
/// Returns the position after evaluation.
pub fn EvalResult::get_pos(self : EvalResult) -> Int {
  self.pos
}

///|
/// Returns the captured labels.
pub fn EvalResult::get_labels(self : EvalResult) -> Map[String, Json] {
  self.labels
}

///|
/// Returns the emitted events.
pub fn EvalResult::get_events(
  self : EvalResult,
) -> Array[(String, Map[String, Json])] {
  self.events
}

///|
/// Gets a label value by name.
pub fn EvalResult::get_label(self : EvalResult, name : String) -> Json? {
  self.labels.get(name)
}

///|
/// Memo key for memoization.
struct MemoKey {
  node_id : Int
  pos : Int
} derive(Eq, Hash, Show)

///|
/// EvalContext holds the evaluation state.
struct EvalContext {
  peg : PEG
  tokens : Array[@types.Tok]
  memo : Map[MemoKey, EvalResult]
  all_events : Array[(String, Map[String, Json])]
  emit_filter : @hashset.HashSet[String]?
}

///|
/// Creates a new evaluation context.
pub fn EvalContext::new(
  peg : PEG,
  tokens : Array[@types.Tok],
  emit_filter? : @hashset.HashSet[String]? = None,
) -> EvalContext {
  { peg, tokens, memo: Map::new(), all_events: [], emit_filter }
}

///|
/// Creates a memo key from a node id and position.
fn make_memo_key(node_id : Int, pos : Int) -> MemoKey {
  { node_id, pos }
}

///|
/// Merges labels into target in place.
/// Special handling for `_text`: concatenate instead of overwrite.
fn merge_labels_in_place(
  target : Map[String, Json],
  overlay : Map[String, Json],
) -> Unit {
  for key, value in overlay {
    // Special handling for _text: concatenate
    if key == "_text" {
      match (target.get("_text"), value) {
        (Some(String(base_text)), String(new_text)) =>
          target.set("_text", (base_text + new_text).to_json())
        _ => target.set(key, value)
      }
    } else {
      target.set(key, value)
    }
  }
}

///|
/// Appends events into target in place.
fn append_events_in_place(
  target : Array[(String, Map[String, Json])],
  more : Array[(String, Map[String, Json])],
) -> Unit {
  for item in more {
    target.push(item)
  }
}

///|
/// Clones labels to avoid mutating memoized result maps.
fn clone_labels(labels : Map[String, Json]) -> Map[String, Json] {
  let copied : Map[String, Json] = Map::new()
  for key, value in labels {
    copied.set(key, value)
  }
  copied
}

///|
/// Clones events array.
fn clone_events(
  events : Array[(String, Map[String, Json])],
) -> Array[(String, Map[String, Json])] {
  let copied : Array[(String, Map[String, Json])] = []
  for event in events {
    copied.push(event)
  }
  copied
}

///|
/// Returns true if a rule event should be emitted.
fn should_emit_rule(ctx : EvalContext, name : String) -> Bool {
  match ctx.emit_filter {
    Some(filter) => filter.contains(name)
    None => true
  }
}

// Trampoline-based evaluation to avoid stack overflow

///|
/// Frame types for the evaluation stack.
priv enum EvalFrame {
  // Evaluate a node and continue
  EvalNode(Int, Int, MemoKey?)
  // Continue sequence evaluation
  SeqCont(
    Array[Int],
    Int,
    Int,
    Map[String, Json],
    Array[(String, Map[String, Json])]
  )
  // Continue choice evaluation
  ChoiceCont(Array[Int], Int, Int)
  // Continue star evaluation
  StarCont(Int, Int, Map[String, Json], Array[(String, Map[String, Json])], Int)
  // Continue plus evaluation (after first match)
  PlusCont(Int, Int, Map[String, Json], Array[(String, Map[String, Json])], Int)
  // Optional continuation
  OptionalCont(Int)
  // Apply label
  LabelCont(String, Int)
  // Rule call continuation
  RuleCont(String, Int)
  // Store memo result
  StoreMemo(MemoKey)
}

///|
/// Evaluates nodes using an explicit stack (trampoline).
fn eval_trampoline(
  ctx : EvalContext,
  start_node_id : Int,
  start_pos : Int,
) -> EvalResult {
  let stack : Array[EvalFrame] = []
  let results : Array[EvalResult] = []

  // Push initial evaluation
  stack.push(EvalNode(start_node_id, start_pos, None))

  while stack.length() > 0 {
    let frame = stack.pop().unwrap()
    match frame {
      EvalNode(node_id, pos, memo_key) => {
        // Check memo first
        let key = match memo_key {
          Some(k) => k
          None => make_memo_key(node_id, pos)
        }
        match ctx.memo.get(key) {
          Some(cached) => {
            results.push(cached)
            continue
          }
          None => ()
        }

        // Push memo storage frame
        stack.push(StoreMemo(key))

        // Evaluate based on node type
        match ctx.peg.get_compiled_node(node_id) {
          Some(compiled) =>
            match compiled {
              CEmpty => results.push(EvalResult::success(pos))
              CSym(name) =>
                if ctx.peg.is_token(name) {
                  // Token match
                  if pos < ctx.tokens.length() && ctx.tokens[pos].kind == name {
                    let tok = ctx.tokens[pos]
                    let labels : Map[String, Json] = Map::new()
                    labels.set("_last", tok.get_value().to_json())
                    labels.set("_last_pos", tok.pos.to_double().to_json())
                    labels.set(
                      "_last_len",
                      tok.text.length().to_double().to_json(),
                    )
                    // Set _text for multi-line accumulation
                    labels.set("_text", tok.text.to_json())
                    results.push(EvalResult::success(pos + 1, labels~))
                  } else {
                    results.push(EvalResult::failure(pos))
                  }
                } else {
                  // Rule reference
                  stack.push(RuleCont(name, pos))
                  match ctx.peg.get_rule_node_id(name) {
                    Some(rule_node_id) =>
                      stack.push(EvalNode(rule_node_id, pos, None))
                    None => results.push(EvalResult::failure(pos))
                  }
                }
              CSeq(elems) =>
                if elems.length() == 0 {
                  results.push(EvalResult::success(pos))
                } else {
                  // Push continuation for sequence
                  stack.push(SeqCont(elems, 1, pos, Map::new(), []))
                  // Evaluate first element
                  stack.push(EvalNode(elems[0], pos, None))
                }
              CChoice(alts) =>
                if alts.length() == 0 {
                  results.push(EvalResult::failure(pos))
                } else {
                  // Push continuation for trying next alternatives
                  stack.push(ChoiceCont(alts, 1, pos))
                  // Try first alternative
                  stack.push(EvalNode(alts[0], pos, None))
                }
              CStar(child) => {
                // Push continuation for star
                stack.push(StarCont(child, pos, Map::new(), [], pos))
                // Try first match
                stack.push(EvalNode(child, pos, None))
              }
              CPlus(child) => {
                // Push continuation for plus (requires at least one match)
                stack.push(PlusCont(child, pos, Map::new(), [], pos))
                // Try first match
                stack.push(EvalNode(child, pos, None))
              }
              COptional(child) => {
                // Optional always succeeds - if child fails, return success at original pos
                stack.push(OptionalCont(pos))
                stack.push(EvalNode(child, pos, None))
              }
              CLabel(name, child) => {
                stack.push(LabelCont(name, pos))
                stack.push(EvalNode(child, pos, None))
              }
            }
          None => results.push(EvalResult::failure(pos))
        }
      }
      SeqCont(elems, idx, orig_pos, labels, events) => {
        // Get result of previous element
        let prev = results.pop().unwrap()
        if not(prev.ok) {
          results.push(EvalResult::failure(orig_pos))
        } else {
          merge_labels_in_place(labels, prev.labels)
          append_events_in_place(events, prev.events)
          let new_pos = prev.pos
          if idx >= elems.length() {
            // All elements matched
            results.push(EvalResult::success(new_pos, labels~, events~))
          } else {
            // Continue with next element
            stack.push(SeqCont(elems, idx + 1, orig_pos, labels, events))
            stack.push(EvalNode(elems[idx], new_pos, None))
          }
        }
      }
      ChoiceCont(alts, idx, orig_pos) => {
        // Get result of previous alternative
        let prev = results.pop().unwrap()
        if prev.ok {
          // Found a match
          results.push(prev)
        } else if idx >= alts.length() {
          // No more alternatives
          results.push(EvalResult::failure(orig_pos))
        } else {
          // Try next alternative
          stack.push(ChoiceCont(alts, idx + 1, orig_pos))
          stack.push(EvalNode(alts[idx], orig_pos, None))
        }
      }
      OptionalCont(orig_pos) => {
        // Optional always succeeds
        let prev = results.pop().unwrap()
        if prev.ok {
          results.push(prev)
        } else {
          // Child failed, but optional succeeds at original position
          results.push(EvalResult::success(orig_pos))
        }
      }
      StarCont(child, start_pos, labels, events, current_pos) => {
        // Get result of previous iteration
        let prev = results.pop().unwrap()
        if not(prev.ok) || prev.pos == current_pos {
          // No match or no progress - done with star
          results.push(EvalResult::success(current_pos, labels~, events~))
        } else {
          // Continue iterating
          merge_labels_in_place(labels, prev.labels)
          append_events_in_place(events, prev.events)
          stack.push(StarCont(child, start_pos, labels, events, prev.pos))
          stack.push(EvalNode(child, prev.pos, None))
        }
      }
      PlusCont(child, start_pos, labels, events, current_pos) => {
        // Get result of previous iteration
        let prev = results.pop().unwrap()
        if labels.length() == 0 && events.length() == 0 {
          // This is the first iteration
          if not(prev.ok) {
            // Plus requires at least one match
            results.push(EvalResult::failure(start_pos))
          } else {
            // First match succeeded, continue like star
            let acc_labels = clone_labels(prev.labels)
            let acc_events = clone_events(prev.events)
            stack.push(
              StarCont(child, start_pos, acc_labels, acc_events, prev.pos),
            )
            stack.push(EvalNode(child, prev.pos, None))
          }
          // Subsequent iterations - same as star
        } else if not(prev.ok) || prev.pos == current_pos {
          results.push(EvalResult::success(current_pos, labels~, events~))
        } else {
          merge_labels_in_place(labels, prev.labels)
          append_events_in_place(events, prev.events)
          stack.push(StarCont(child, start_pos, labels, events, prev.pos))
          stack.push(EvalNode(child, prev.pos, None))
        }
      }
      LabelCont(name, orig_pos) => {
        let prev = results.pop().unwrap()
        if not(prev.ok) {
          results.push(EvalResult::failure(orig_pos))
        } else {
          let labels = prev.labels
          // Copy _last to the label name (processed single-token value)
          match labels.get("_last") {
            Some(v) => labels.set(name, v)
            None => labels.set(name, Json::null())
          }
          // Copy _last_pos to name_pos
          match labels.get("_last_pos") {
            Some(v) => labels.set(name + "_pos", v)
            None => ()
          }
          // Copy _last_len to name_len
          match labels.get("_last_len") {
            Some(v) => labels.set(name + "_len", v)
            None => ()
          }
          // Copy _text to name_text (accumulated multi-line text)
          match labels.get("_text") {
            Some(v) => labels.set(name + "_text", v)
            None => ()
          }
          results.push(
            EvalResult::success(prev.pos, labels~, events=prev.events),
          )
        }
      }
      RuleCont(name, _orig_pos) => {
        let prev = results.pop().unwrap()
        if prev.ok {
          // Emit event for this matched rule
          if should_emit_rule(ctx, name) {
            let event_labels : Map[String, Json] = Map::new()
            for key, value in prev.labels {
              event_labels.set(key, value)
            }
            ctx.all_events.push((name, event_labels))
          }
          // Clean labels - keep _last and _text for parent scope
          let clean_labels : Map[String, Json] = Map::new()
          match prev.labels.get("_last") {
            Some(v) => clean_labels.set("_last", v)
            None => ()
          }
          match prev.labels.get("_last_pos") {
            Some(v) => clean_labels.set("_last_pos", v)
            None => ()
          }
          match prev.labels.get("_last_len") {
            Some(v) => clean_labels.set("_last_len", v)
            None => ()
          }
          // Also keep _text for multi-line capture
          match prev.labels.get("_text") {
            Some(v) => clean_labels.set("_text", v)
            None => ()
          }
          results.push(
            EvalResult::success(
              prev.pos,
              labels=clean_labels,
              events=prev.events,
            ),
          )
        } else {
          results.push(prev)
        }
      }
      StoreMemo(key) => {
        // Get result and store in memo, then push back
        let result = results.pop().unwrap()
        ctx.memo.set(key, result)
        results.push(result)
      }
    }
  }

  if results.length() > 0 {
    results.pop().unwrap()
  } else {
    EvalResult::failure(start_pos)
  }
}

///|
/// Runs a PEG parse from a start rule over tokens.
/// Returns the final result with labels and events, or None on failure.
/// Events include rule match notifications for semantic processing.
fn run_parse_internal(
  peg : PEG,
  start_rule : String,
  tokens : Array[@types.Tok],
  emit_filter : @hashset.HashSet[String]?,
) -> EvalResult? {
  let ctx = EvalContext::new(peg, tokens, emit_filter~)

  // Get compiled start rule node id
  match peg.get_rule_node_id(start_rule) {
    None => None
    Some(start_node_id) => {
      let result = eval_trampoline(ctx, start_node_id, 0)
      if result.ok {
        // Merge all rule match events into the result
        let merged_events = clone_events(result.events)
        append_events_in_place(merged_events, ctx.all_events)
        Some(
          EvalResult::success(
            result.pos,
            labels=result.labels,
            events=merged_events,
          ),
        )
      } else {
        None
      }
    }
  }
}

///|
/// Runs a PEG parse and emits all matched rule events.
pub fn run_parse(
  peg : PEG,
  _spec : @types.KGFSpec,
  start_rule : String,
  tokens : Array[@types.Tok],
) -> EvalResult? {
  run_parse_internal(peg, start_rule, tokens, None)
}

///|
/// Runs a PEG parse while emitting only a subset of rule events.
pub fn run_parse_filtered(
  peg : PEG,
  _spec : @types.KGFSpec,
  start_rule : String,
  tokens : Array[@types.Tok],
  active_rules : @hashset.HashSet[String],
) -> EvalResult? {
  run_parse_internal(peg, start_rule, tokens, Some(active_rules))
}
