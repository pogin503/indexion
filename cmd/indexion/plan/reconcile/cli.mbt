///|
/// Entry point for the reconcile subcommand via argparse matches.
pub async fn run_matches(matches : @argparse.Matches) -> Unit {
  let config = resolve_config_from_matches(matches)
  run_with_config(config)
}

///|
async fn run_with_config(config : ReconcileConfig) -> Unit {
  if config.target_dir.length() == 0 {
    println("Error: directory path required.")
    println("")
    println(command().render_help())
    return
  }
  let report = match @reconcile_plan.persisted_report(config) {
    Some(value) => value
    None => return
  }
  @common.write_output(
    config.output,
    render_output(report, config.format),
    label="Reconcile report",
  )
}

///|
pub async fn run_to_string(config : ReconcileConfig) -> String? {
  match @reconcile_plan.report(config) {
    Some(report) => Some(render_output(report, config.format))
    None => None
  }
}
