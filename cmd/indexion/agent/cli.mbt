///|
/// # indexion agent
///
/// Agent-facing orientation and workflow helpers.

///|
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "agent",
    about="Generate agent orientation context before coding",
    subcommand_required=true,
    subcommands=[orient_command()],
  )
}

///|
pub fn dispatch(matches : @argparse.Matches) -> Unit {
  guard matches.subcommand is Some((name, sub)) else { return }
  match name {
    "orient" => run_orient(sub)
    _ => ()
  }
}

///|
fn orient_command() -> @argparse.Command {
  @argparse.Command(
    "orient",
    about="Build a pre-edit structure brief for coding agents",
    options=[
      @argparse.OptionArg("specs-dir", about=@help.specs_dir, default_values=[
        "kgfs",
      ]),
      @argparse.OptionArg::new(
        "task",
        about="Task description text. Use --task-file for longer prompts.",
        default_values=[""],
      ),
      @argparse.OptionArg::new(
        "task-file",
        about="Path to a file containing the task description.",
        default_values=[""],
      ),
      @argparse.OptionArg::new("format", about="Output format: md | json", default_values=[
        "md",
      ]),
      @argparse.OptionArg::new(
        "output",
        about="Output file path (- or empty = stdout)",
        default_values=[""],
      ),
      @argparse.OptionArg::new("limit", about="Maximum entries per section", default_values=[
        "12",
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
fn run_orient(matches : @argparse.Matches) -> Unit {
  let config = orient_config_from_matches(matches)
  let report = @agent_orient.orient_agent(config)
  let rendered = match @common.arg_str(matches, "format", "md") {
    "json" => report.to_json().stringify(indent=2) + "\n"
    _ => render_markdown(report)
  }
  @common.write_output(
    @common.arg_str(matches, "output", ""),
    rendered,
    label="Agent orientation brief",
  )
}

///|
fn orient_config_from_matches(
  matches : @argparse.Matches,
) -> @agent_orient.AgentOrientConfig {
  let base = @agent_orient.AgentOrientConfig::default()
  {
    task: task_from_matches(matches),
    paths: match matches.values.get("paths") {
      Some(arr) if arr.length() > 0 => arr
      _ => base.paths
    },
    specs_dir: @common.arg_str(matches, "specs-dir", base.specs_dir),
    limit: @common.arg_int(matches, "limit", base.limit),
  }
}

///|
fn task_from_matches(matches : @argparse.Matches) -> String {
  let task_file = @common.arg_str(matches, "task-file", "")
  if task_file.length() > 0 {
    return @fs.read_file_to_string(task_file) catch { _ => "" }
  }
  @common.arg_str(matches, "task", "")
}

///|
fn render_markdown(report : @agent_orient.AgentOrientReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Agent Orientation Brief\n\n")
  if report.task.length() > 0 {
    buf.write_string("## Task\n\n")
    buf.write_string(report.task)
    buf.write_string("\n\n")
  }
  render_items(buf, "Likely Owners", report.likely_owners)
  render_items(buf, "Consumer Surfaces", report.consumer_surfaces)
  render_items(buf, "Do Not Implement Here", report.do_not_implement_here)
  render_items(buf, "Required Preflight", report.required_preflight)
  render_evidence(buf, report.evidence)
  render_list(buf, "Workflow", report.workflow)
  render_list(buf, "Notes", report.notes)
  buf.to_string()
}

///|
fn render_items(
  buf : StringBuilder,
  title : String,
  items : Array[@agent_orient.AgentOrientItem],
) -> Unit {
  buf.write_string("## ")
  buf.write_string(title)
  buf.write_string("\n\n")
  if items.length() == 0 {
    buf.write_string("- None found.\n\n")
    return
  }
  for item in items {
    buf.write_string("- `")
    buf.write_string(item.path)
    buf.write_string("`: ")
    buf.write_string(item.reason)
    buf.write_string("\n")
  }
  buf.write_string("\n")
}

///|
fn render_evidence(
  buf : StringBuilder,
  evidence : Array[@agent_orient.AgentOrientEvidence],
) -> Unit {
  buf.write_string("## Evidence\n\n")
  if evidence.length() == 0 {
    buf.write_string("- None found.\n\n")
    return
  }
  for item in evidence {
    buf.write_string("- `")
    buf.write_string(item.path)
    buf.write_string("` [")
    buf.write_string(item.kind)
    buf.write_string("] score=")
    buf.write_string(@common.format_percent(item.score))
    if item.matched_terms.length() > 0 {
      buf.write_string(" terms=`")
      buf.write_string(item.matched_terms.join("`, `"))
      buf.write_string("`")
    }
    buf.write_string("\n")
  }
  buf.write_string("\n")
}

///|
fn render_list(
  buf : StringBuilder,
  title : String,
  items : Array[String],
) -> Unit {
  buf.write_string("## ")
  buf.write_string(title)
  buf.write_string("\n\n")
  for item in items {
    buf.write_string("- ")
    buf.write_string(item)
    buf.write_string("\n")
  }
  buf.write_string("\n")
}
