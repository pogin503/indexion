///|
/// HTTP fetch error.
pub suberror FetchError {
  FetchError(String)
}

///|
/// Stub for non-native targets.
#warnings("-unused_async")
pub async fn fetch_bytes(
  _url : String,
  headers~ : Map[String, String],
) -> Bytes raise FetchError {
  ignore(headers)
  raise FetchError("HTTP fetch not available on this platform")
}

///|
/// Stub for non-native targets.
#warnings("-unused_async")
pub async fn fetch_text(
  _url : String,
  headers~ : Map[String, String],
) -> String raise FetchError {
  ignore(headers)
  raise FetchError("HTTP fetch not available on this platform")
}
