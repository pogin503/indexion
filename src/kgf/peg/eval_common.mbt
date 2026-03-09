///|
/// Common types and utilities for PEG evaluators.
/// Shared between recursive and iterative implementations.

///|
/// Memo entry states for memoization.
/// Stores labels to support labeled captures across backtracking.
priv enum MemoState {
  Unknown
  Failed
  Succeeded(Int, Map[String, Json]) // (end_pos, labels)
}

///|
/// FastEvalResult holds evaluation result with labels.
priv struct FastEvalResult {
  ok : Bool
  end_pos : Int
  labels : Map[String, Json]
}

///|
/// Creates empty labels map.
fn empty_labels() -> Map[String, Json] {
  Map::new()
}

///|
/// Merges labels from source into target (in place).
/// Special handling for _text: concatenates instead of replacing.
fn merge_labels(target : Map[String, Json], source : Map[String, Json]) -> Unit {
  for key, value in source {
    if key == "_text" {
      match (target.get("_text"), value) {
        (Some(String(base)), String(new_text)) =>
          target.set("_text", (base + new_text).to_json())
        _ => target.set(key, value)
      }
    } else {
      target.set(key, value)
    }
  }
}

///|
/// Pre-computes token IDs for fast matching.
/// Returns an array mapping token positions to their IDs (-1 if unknown).
fn compute_token_ids(peg : PEG, tokens : Array[@types.Tok]) -> Array[Int] {
  let token_ids : Array[Int] = Array::make(tokens.length(), -1)
  for i = 0; i < tokens.length(); i = i + 1 {
    let kind = tokens[i].kind
    match peg.get_token_id(kind) {
      Some(id) => token_ids[i] = id
      None => token_ids[i] = -1
    }
  }
  token_ids
}

///|
/// Creates memoization array for PEG evaluation.
fn create_memo(num_nodes : Int, num_positions : Int) -> Array[MemoState] {
  let memo_size = num_nodes * num_positions
  Array::make(memo_size, Unknown)
}
