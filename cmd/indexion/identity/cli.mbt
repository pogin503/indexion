///|
/// # indexion identity
///
/// Commands for auditing whether names still point at the content they claim to
/// identify.

///|
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "identity",
    about="Audit name/content identity",
    subcommand_required=true,
    subcommands=[audit_command()],
  )
}

///|
pub fn dispatch(matches : @argparse.Matches) -> Unit {
  guard matches.subcommand is Some((name, sub)) else { return }
  match name {
    "audit" => run_audit(sub)
    _ => ()
  }
}

///|
fn audit_command() -> @argparse.Command {
  @argparse.Command(
    "audit",
    about="Detect file/folder/symbol name drift against code content",
    flags=[
      @argparse.FlagArg::new(
        "no-symbols",
        about="Skip function/type/variable symbol identity checks",
      ),
      @argparse.FlagArg::new(
        "no-folders",
        about="Skip aggregate folder identity checks",
      ),
    ],
    options=[
      @argparse.OptionArg("specs-dir", about=@help.specs_dir, default_values=[
        "kgfs",
      ]),
      @argparse.OptionArg::new("format", about="Output format: text | json", default_values=[
        "text",
      ]),
      @argparse.OptionArg::new(
        "output",
        about="Output file path (- or empty = stdout)",
        default_values=[""],
      ),
      @argparse.OptionArg::new(
        "threshold",
        about="Minimum divergence to show as review candidate",
        default_values=["0.62"],
      ),
      @argparse.OptionArg::new("limit", about="Maximum candidates to render", default_values=[
        "50",
      ]),
    ],
    positionals=[
      @argparse.PositionArg(
        "paths",
        num_args=@argparse.ValueRange(lower=0),
        about="Input files or directories",
      ),
    ],
  )
}

///|
fn run_audit(matches : @argparse.Matches) -> Unit {
  let config = audit_config_from_matches(matches)
  let report = @identity_core.audit_code_identity(config)
  let format = @common.arg_str(matches, "format", "text")
  let rendered = match format {
    "json" => report.to_json().stringify(indent=2) + "\n"
    _ => render_audit_text(report)
  }
  @common.write_output(
    @common.arg_str(matches, "output", ""),
    rendered,
    label="Identity audit report",
  )
}

///|
fn audit_config_from_matches(
  matches : @argparse.Matches,
) -> @identity_core.IdentityAuditConfig {
  let base = @identity_core.IdentityAuditConfig::default()
  {
    paths: match matches.values.get("paths") {
      Some(arr) if arr.length() > 0 => arr
      _ => base.paths
    },
    specs_dir: @common.arg_str(matches, "specs-dir", base.specs_dir),
    threshold: @common.arg_double(matches, "threshold", base.threshold),
    limit: @common.arg_int(matches, "limit", base.limit),
    include_symbols: !matches.flags.get("no-symbols").unwrap_or(false),
    include_folders: !matches.flags.get("no-folders").unwrap_or(false),
  }
}

///|
fn render_audit_text(report : @identity_core.IdentityAuditReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("=== indexion identity audit ===\n")
  buf.write_string("Scanned: ")
  buf.write_string(report.summary.scanned.to_string())
  buf.write_string("\nCandidates: ")
  buf.write_string(report.summary.candidates.to_string())
  buf.write_string("\nThreshold: ")
  buf.write_string(@common.format_percent(report.summary.threshold))
  buf.write_string("\nMax divergence: ")
  buf.write_string(@common.format_percent(report.summary.max_divergence))
  buf.write_string("\n\n")
  if report.candidates.length() == 0 {
    buf.write_string("No identity candidates exceeded the review threshold.\n")
    return buf.to_string()
  }
  for candidate in report.candidates {
    buf.write_string("## ")
    buf.write_string(candidate.kind)
    buf.write_string(" `")
    buf.write_string(candidate.path)
    buf.write_string("`\n")
    buf.write_string("- Name: `")
    buf.write_string(candidate.name)
    buf.write_string("`\n")
    buf.write_string("- Divergence: ")
    buf.write_string(@common.format_percent(candidate.divergence))
    buf.write_string(" (similarity ")
    buf.write_string(@common.format_percent(candidate.similarity))
    buf.write_string(")\n")
    buf.write_string("- Action: `")
    buf.write_string(candidate.recommendation)
    buf.write_string("`\n")
    buf.write_string("- Assessment: `")
    buf.write_string(candidate.assessment)
    buf.write_string("`\n")
    if candidate.prominent_unused.length() > 0 {
      buf.write_string("- Prominent unused: `")
      buf.write_string(candidate.prominent_unused.join("`, `"))
      buf.write_string("`\n")
    }
    buf.write_string("- Expected: ")
    buf.write_string(@common.truncate(candidate.expected_summary, 220))
    buf.write_string("\n")
    buf.write_string("- Actual: ")
    buf.write_string(@common.truncate(candidate.actual_summary, 220))
    buf.write_string("\n\n")
  }
  buf.to_string()
}
