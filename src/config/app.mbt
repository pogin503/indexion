///|
/// indexion application constants and directory resolution.
/// Application-specific knowledge that depends on platform detection.

///|
/// Get OS-standard configuration directory for indexion.
/// - macOS: ~/Library/Application Support/Indexion
/// - Linux: $XDG_CONFIG_HOME/indexion or ~/.config/indexion
/// - Windows: %APPDATA%\Indexion
pub fn get_global_config_dir() -> String? {
  match @platform.detect_platform() {
    MacOS =>
      match @platform.get_home_dir() {
        Some(home) => Some(home + "/Library/Application Support/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_CONFIG_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match @platform.get_home_dir() {
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
      match @platform.get_home_dir() {
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
  match @platform.detect_platform() {
    MacOS =>
      match @platform.get_home_dir() {
        Some(home) => Some(home + "/Library/Application Support/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_DATA_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match @platform.get_home_dir() {
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
      match @platform.get_home_dir() {
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
  match @platform.detect_platform() {
    MacOS =>
      match @platform.get_home_dir() {
        Some(home) => Some(home + "/Library/Caches/Indexion")
        None => None
      }
    Linux => {
      match @sys.get_env_var("XDG_CACHE_HOME") {
        Some(xdg) => if xdg.length() > 0 { return Some(xdg + "/indexion") }
        None => ()
      }
      match @platform.get_home_dir() {
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
      match @platform.get_home_dir() {
        Some(home) => Some(home + "/.cache/indexion")
        None => None
      }
  }
}

///|
/// Get the indexion install directory.
/// Priority: INDEXION_INSTALL_DIR env var, then ~/.indexion
/// This is the SoT for install directory resolution.
pub fn get_install_dir() -> String? {
  match @sys.get_env_var("INDEXION_INSTALL_DIR") {
    Some(dir) => if dir.length() > 0 { return Some(dir) }
    None => ()
  }
  match @platform.get_home_dir() {
    Some(home) => Some(home + "/.indexion")
    None => None
  }
}

///|
/// Get the platform asset name for release downloads.
/// Maps Platform + Arch to the asset naming convention used in GitHub Releases.
/// This is the SoT for platform-to-asset mapping.
pub fn get_platform_asset_name() -> String? {
  let arch = @platform.detect_arch()
  let arch_str = match arch {
    X64 => "x64"
    Arm64 => "arm64"
    UnknownArch => return None
  }
  match @platform.detect_platform() {
    MacOS => Some("indexion-darwin-" + arch_str)
    Linux => Some("indexion-linux-" + arch_str)
    Windows => Some("indexion-windows-" + arch_str)
    Unknown => None
  }
}

///|
/// Get the archive extension for the current platform.
pub fn get_archive_extension() -> String {
  match @platform.detect_platform() {
    Windows => ".zip"
    _ => ".tar.gz"
  }
}

///|
/// Get the binary name for the current platform.
pub fn get_binary_name() -> String {
  match @platform.detect_platform() {
    Windows => "indexion.exe"
    _ => "indexion"
  }
}
