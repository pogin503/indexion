///|
/// Spec CLI - Specification-driven analysis.
/// Subcommands:
///   verify - Check spec-to-implementation conformance

///|
/// Build the argparse Command for the spec subcommand.
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "spec",
    about="Specification-driven analysis (verify conformance, etc.)",
    subcommand_required=true,
    subcommands=[@verify.command()],
  )
}

///|
/// Dispatch spec subcommand based on parsed matches.
pub fn dispatch(matches : @argparse.Matches) -> Unit {
  guard matches.subcommand is Some((name, sub)) else { return }
  match name {
    "verify" => @verify.run_matches(sub)
    _ => ()
  }
}
