///|
/// # indexion update
///
/// Check for updates and install the latest version.
///
/// ## Usage
///
/// ```bash
/// indexion update [options]
/// ```

///|
/// Configuration for update command.
pub struct UpdateConfig {
  check_only : Bool
  force : Bool
  show_help : Bool
}

///|
/// Create a default UpdateConfig with all options disabled.
pub fn UpdateConfig::default() -> UpdateConfig {
  { check_only: false, force: false, show_help: false }
}

///|
/// Parse command-line arguments for the update subcommand.
pub fn parse_args(args : Array[String], start_idx : Int) -> UpdateConfig {
  let mut config = UpdateConfig::default()
  for i = start_idx; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      config = { ..config, show_help: true }
    } else if arg == "--check" {
      config = { ..config, check_only: true }
    } else if arg == "--force" {
      config = { ..config, force: true }
    }
  }
  config
}

///|
/// Display help text for the update subcommand.
pub fn show_help() -> Unit {
  println("indexion update - Check for updates and install the latest version")
  println("")
  println("Usage:")
  println("  indexion update [options]")
  println("")
  println("Options:")
  println("  --check      Check for updates only (do not download)")
  println("  --force      Reinstall even if already on latest version")
  println("  --help, -h   Show this help message")
  println("")
  println("Examples:")
  println("  indexion update          # Update to latest version")
  println("  indexion update --check  # Check if an update is available")
  println("  indexion update --force  # Force reinstall current version")
}

///|
/// Entry point for the update subcommand.
pub async fn run(args : Array[String], start_idx : Int) -> Unit {
  let config = parse_args(args, start_idx)
  if config.show_help {
    show_help()
    return
  }
  run_async(config)
}

///|
async fn run_async(config : UpdateConfig) -> Unit {
  let result = @update_core.check_for_update() catch {
    err => {
      println("Error checking for updates: " + err.to_string())
      return
    }
  }
  println("Current version: " + result.current_version)
  println("Latest version:  " + result.latest_version)
  if config.check_only {
    if result.has_update {
      println("")
      println("Update available! Run 'indexion update' to install.")
    } else {
      println("")
      println("You are on the latest version.")
    }
    return
  }
  if not(result.has_update) && not(config.force) {
    println("")
    println("Already up to date.")
    return
  }
  println("")
  @update_core.perform_update(result.latest_version) catch {
    err => {
      println("Update failed: " + err.to_string())
      return
    }
  }
}
