///|
/// Platform detection and OS-standard directory resolution.
/// Follows XDG Base Directory Specification (Linux), Apple HIG (macOS),
/// and Known Folder API conventions (Windows).

///|
/// Detected operating system platform.
pub enum Platform {
  MacOS
  Linux
  Windows
  Unknown
} derive(Eq, Show)

///|
/// Detect the current operating system platform.
/// Uses environment variables and path patterns for detection.
pub fn detect_platform() -> Platform {
  // Windows detection: USERPROFILE with Windows path pattern
  match @sys.get_env_var("USERPROFILE") {
    Some(p) =>
      if p.length() > 0 &&
        (
          p.has_prefix("C:\\") ||
          p.has_prefix("c:\\") ||
          p.contains("\\Users\\")
        ) {
        return Windows
      }
    None => ()
  }
  // Unix-like detection via HOME
  match @sys.get_env_var("HOME") {
    Some(h) =>
      if h.length() > 0 {
        // macOS: HOME starts with /Users/
        if h.has_prefix("/Users/") {
          return MacOS
        }
        // Additional macOS check: Library folder existence
        if is_valid_dir_check(h + "/Library") {
          return MacOS
        }
        // Otherwise assume Linux/Unix
        return Linux
      }
    None => ()
  }
  Unknown
}

///|
/// Get OS-standard configuration directory for indexion.
/// - macOS: ~/Library/Application Support/Indexion
/// - Linux: $XDG_CONFIG_HOME/indexion or ~/.config/indexion
/// - Windows: %APPDATA%\Indexion
pub fn get_global_config_dir() -> String? {
  match detect_platform() {
    MacOS =>
      match get_home_dir() {
        Some(home) => Some(home + "/Library/Application Support/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_CONFIG_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match get_home_dir() {
        Some(home) => Some(home + "/.config/indexion")
        None => None
      }
    }
    Windows =>
      match @sys.get_env_var("APPDATA") {
        Some(appdata) =>
          if appdata.length() > 0 {
            Some(appdata + "/Indexion")
          } else {
            None
          }
        None => None
      }
    Unknown =>
      match get_home_dir() {
        Some(home) => Some(home + "/.config/indexion")
        None => None
      }
  }
}

///|
/// Get OS-standard data directory for indexion.
/// - macOS: ~/Library/Application Support/Indexion
/// - Linux: $XDG_DATA_HOME/indexion or ~/.local/share/indexion
/// - Windows: %LOCALAPPDATA%\Indexion
pub fn get_global_data_dir() -> String? {
  match detect_platform() {
    MacOS =>
      match get_home_dir() {
        Some(home) => Some(home + "/Library/Application Support/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_DATA_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match get_home_dir() {
        Some(home) => Some(home + "/.local/share/indexion")
        None => None
      }
    }
    Windows =>
      match @sys.get_env_var("LOCALAPPDATA") {
        Some(localappdata) =>
          if localappdata.length() > 0 {
            Some(localappdata + "/Indexion")
          } else {
            None
          }
        None => None
      }
    Unknown =>
      match get_home_dir() {
        Some(home) => Some(home + "/.local/share/indexion")
        None => None
      }
  }
}

///|
/// Get OS-standard cache directory for indexion.
/// - macOS: ~/Library/Caches/Indexion
/// - Linux: $XDG_CACHE_HOME/indexion or ~/.cache/indexion
/// - Windows: %LOCALAPPDATA%\Indexion\Cache
pub fn get_global_cache_dir() -> String? {
  match detect_platform() {
    MacOS =>
      match get_home_dir() {
        Some(home) => Some(home + "/Library/Caches/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_CACHE_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match get_home_dir() {
        Some(home) => Some(home + "/.cache/indexion")
        None => None
      }
    }
    Windows =>
      match @sys.get_env_var("LOCALAPPDATA") {
        Some(localappdata) =>
          if localappdata.length() > 0 {
            Some(localappdata + "/Indexion/Cache")
          } else {
            None
          }
        None => None
      }
    Unknown =>
      match get_home_dir() {
        Some(home) => Some(home + "/.cache/indexion")
        None => None
      }
  }
}

///|
/// Internal helper to check if a path is a valid directory.
fn is_valid_dir_check(path : String) -> Bool {
  @fs.is_dir(path) catch {
    _ => false
  }
}
