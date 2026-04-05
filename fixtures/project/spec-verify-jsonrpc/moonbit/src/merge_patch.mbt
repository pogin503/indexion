///|
/// Apply a JSON Merge Patch (RFC 7396) to a target document.
pub fn merge_patch(target : Json, patch : Json) -> Json {
  match patch {
    Object(patch_obj) => {
      let result = match target {
        Object(target_obj) => {
          let merged : Map[String, Json] = {}
          for key, value in target_obj {
            merged[key] = value
          }
          merged
        }
        _ => {
          let empty : Map[String, Json] = {}
          empty
        }
      }
      for name, value in patch_obj {
        match value {
          Null => {
            result.remove(name)
          }
          _ => result[name] = merge_patch(
              result.get(name).unwrap_or(Json::Null),
              value,
            )
        }
      }
      Json::Object(result)
    }
    _ => patch
  }
}
