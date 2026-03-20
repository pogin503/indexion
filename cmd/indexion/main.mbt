///|
/// # indexion
///
/// Source code exploration and documentation tool.
///
/// ## Overview
///
/// indexion provides tools for analyzing, exploring, and documenting source code.
/// Named after Korzybski's "the map is not the territory" - indexion helps build
/// dynamic maps of your codebase.
///
/// ## Installation
///
/// ```bash
/// # Build from source
/// moon build --target native
///
/// # Or download release
/// # See: https://github.com/trkbt10/indexion/releases
/// ```
///
/// ## Commands
///
/// | Command | Description |
/// |---------|-------------|
/// | `explore` | Analyze file similarity in a directory |
/// | `plan refactor` | Generate refactoring plan from similarity |
/// | `plan documentation` | Analyze documentation coverage |
/// | `plan unwrap` | Detect unnecessary wrapper functions |
/// | `plan solid` | Plan cross-package code extraction |
/// | `plan reconcile` | Detect implementation/documentation drift |
/// | `doc graph` | Generate dependency graph |
/// | `doc readme` | Generate README from source doc comments |
/// | `digest` | Purpose-based function index |
/// | `kgf` | KGF spec management and inspection |
/// | `sim` | Calculate text similarity/distance |
/// | `segment` | Split text into contextual segments |
/// | `perf kgf` | Run KGF parser performance benchmarks |
///
/// ## Quick Start
///
/// ```bash
/// # Explore similarity in your codebase
/// indexion explore --format=list src/
///
/// # Generate refactoring plan
/// indexion plan refactor --threshold=0.8 src/
///
/// # Generate dependency graph
/// indexion doc graph --format=mermaid src/
/// ```
///
/// ## Configuration
///
/// - KGF specs: `kgfs/` directory for language specifications
/// - Doc config: `doc.json` for documentation generation settings

///|
/// Main entry point.
async fn main {
  let args = @sys.get_cli_args()

  // Find subcommand (skip program name)
  let subcommand = if args.length() > 1 { args[1] } else { "help" }

  match subcommand {
    "init" => @init_cli.run(args, 2)
    "explore" => @explore_cli.run(args, 2)
    "plan" => @plan_cli.run(args, 2)
    "doc" => @doc_cli.run(args, 2)
    "kgf" => @kgf_cli.run(args, 2)
    "digest" => @digest_cli.run(args, 2)
    "sim" | "similarity" => @similarity_cli.run(args, 2)
    "segment" | "seg" => @segment_cli.run(args, 2)
    "perf" => @perf_cli.run(args, 2)
    "update" => @update_cli.run(args, 2)
    "version" | "-v" | "--version" => show_version()
    "help" | "-h" | "--help" => show_help()
    _ => {
      println("Unknown command: " + subcommand)
      println("")
      show_help()
    }
  }
}

///|
/// Show main help message.
fn show_help() -> Unit {
  println("indexion - Source code exploration and documentation tool")
  println("")
  println("Usage:")
  println("  indexion <command> [options]")
  println("")
  println("Commands:")
  println("  init        Initialize indexion configuration")
  println("  explore     Analyze similarity across files in a directory")
  println("  segment     Split text into contextual segments")
  println("  plan        Generate planning documents (refactor, solid, unwrap, etc.)")
  println("  doc         Documentation commands (graph, readme, init)")
  println("  digest      Purpose-based function index (build, query, stats)")
  println(
    "  kgf         KGF spec management (list, update, add) and inspection",
  )
  println("  sim         Calculate text similarity/distance")
  println("  perf        Performance benchmark commands")
  println("  update      Check for and install updates")
  println("  help        Show this help message")
  println("  version     Show version information")
  println("")
  println("Run 'indexion <command> --help' for more information on a command.")
  println("")
  println("Examples:")
  println("  indexion explore --format=list src/")
  println("  indexion plan refactor --threshold=0.8 src/")
  println("  indexion doc graph --format=mermaid src/")
  println("  indexion sim \"hello world\" \"hello there\"")
  println("  indexion perf kgf --iterations=30")
}

///|
/// Show version information.
fn show_version() -> Unit {
  println("indexion version " + @update.current_version)
}
