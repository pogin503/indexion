///|
/// Determine the platform asset name for the current OS, delegating to config SoT.
pub fn get_platform_asset() -> String raise UpdateError {
  match @config.get_platform_asset_name() {
    Some(name) => name
    None => raise UpdateError::PlatformError("Unsupported platform")
  }
}

///|
/// Build the download URL for a release asset.
pub fn build_download_url(version : String, asset : String) -> String {
  "https://github.com/" +
  repo +
  "/releases/download/" +
  version +
  "/" +
  asset +
  @config.get_archive_extension()
}

///|
/// Build the checksum URL for a release asset.
pub fn build_checksum_url(version : String, asset : String) -> String {
  build_download_url(version, asset) + ".sha256"
}

///|
/// Maximum number of redirects to follow.
let max_redirects : Int = 5

///|
/// Download a file from URL and return its content as Bytes.
/// Follows HTTP 3xx redirects up to max_redirects times.
pub async fn download_bytes(url : String) -> Bytes raise UpdateError {
  let mut current_url = url
  for i = 0; i < max_redirects; i = i + 1 {
    let headers : Map[String, String] = {
      "User-Agent": "indexion/" + current_version,
    }
    let (response, body_data) = @mhttp.get(current_url, headers~) catch {
      err => raise UpdateError::NetworkError(err.to_string())
    }
    if response.code == 200 {
      return body_data.binary()
    }
    if response.code >= 300 && response.code < 400 {
      match response.headers.get("location") {
        Some(location) => current_url = location
        None =>
          raise UpdateError::DownloadError(
            "Redirect without Location header: " + current_url,
          )
      }
      continue
    }
    raise UpdateError::DownloadError(
      "Download failed with status " +
      response.code.to_string() +
      ": " +
      current_url,
    )
  }
  raise UpdateError::DownloadError("Too many redirects: " + url)
}

///|
/// Download a text file from URL.
/// Follows HTTP 3xx redirects up to max_redirects times.
pub async fn download_text(url : String) -> String raise UpdateError {
  let mut current_url = url
  for i = 0; i < max_redirects; i = i + 1 {
    let headers : Map[String, String] = {
      "User-Agent": "indexion/" + current_version,
    }
    let (response, body_data) = @mhttp.get(current_url, headers~) catch {
      err => raise UpdateError::NetworkError(err.to_string())
    }
    if response.code == 200 {
      return body_data.text() catch {
        _ => raise UpdateError::ParseError("Failed to decode response as text")
      }
    }
    if response.code >= 300 && response.code < 400 {
      match response.headers.get("location") {
        Some(location) => current_url = location
        None =>
          raise UpdateError::DownloadError(
            "Redirect without Location header: " + current_url,
          )
      }
      continue
    }
    raise UpdateError::DownloadError(
      "Download failed with status " +
      response.code.to_string() +
      ": " +
      current_url,
    )
  }
  raise UpdateError::DownloadError("Too many redirects: " + url)
}

///|
/// Verify SHA-256 checksum of data against expected hash.
pub fn verify_checksum(
  data : Bytes,
  expected_hex : String,
) -> Unit raise UpdateError {
  let hash = @crypto.sha256(data)
  let actual_hex = @crypto.bytes_to_hex_string(hash)
  let expected_trimmed = extract_hash_from_checksum(expected_hex)
  if actual_hex != expected_trimmed {
    raise UpdateError::ChecksumError(
      "Checksum mismatch: expected " + expected_trimmed + ", got " + actual_hex,
    )
  }
}

///|
/// Extract the hash from a checksum file line (first whitespace-delimited field).
fn extract_hash_from_checksum(line : String) -> String {
  let trimmed = trim_string(line)
  let chars = trimmed.to_array()
  let result : Array[Char] = []
  for ch in chars {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      break
    }
    result.push(ch)
  }
  String::from_array(result)
}

///|
fn trim_string(s : String) -> String {
  let chars = s.to_array()
  let mut start = 0
  let mut end = chars.length()
  while start < end &&
        (
          chars[start] == ' ' ||
          chars[start] == '\t' ||
          chars[start] == '\n' ||
          chars[start] == '\r'
        ) {
    start += 1
  }
  while end > start &&
        (
          chars[end - 1] == ' ' ||
          chars[end - 1] == '\t' ||
          chars[end - 1] == '\n' ||
          chars[end - 1] == '\r'
        ) {
    end -= 1
  }
  let result : Array[Char] = []
  for i in start..<end {
    result.push(chars[i])
  }
  String::from_array(result)
}
