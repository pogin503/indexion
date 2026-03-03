///|
/// Doc CLI - Documentation related commands.
/// Subcommands:
///   gen - Generate documentation from source files

///|
pub fn show_help() -> Unit {
  println("indexion doc - Documentation commands")
  println("")
  println("Usage:")
  println("  indexion doc <command> [options]")
  println("")
  println("Commands:")
  println("  gen    Generate documentation from source files")
  println("")
  println("Use 'indexion doc <command> --help' for more information about a command.")
}

///|
pub fn run(args : Array[String], start_idx : Int) -> Unit {
  if start_idx >= args.length() {
    show_help()
    return
  }
  let subcommand = args[start_idx]
  match subcommand {
    "gen" | "generate" => @gen.run(args, start_idx + 1)
    "--help" | "-h" | "help" => show_help()
    _ => {
      println("Unknown doc command: " + subcommand)
      println("")
      show_help()
    }
  }
}
