///|
/// MCP tool registration.
/// Proxies existing CLI commands as MCP tools, using their run_to_json/run_to_string
/// as the single source of truth for tool behavior.

///|
/// Build an MCP server with all indexion tools registered.
fn build_server(config : McpConfig) -> @mcp_server.McpServer {
  let server = @mcp_server.McpServer::new({
    name: "indexion",
    version: @update.current_version,
  })
  register_explore(server, config)
  register_doc_graph(server, config)
  register_kgf_tokens(server, config)
  register_kgf_edges(server, config)
  register_plan_refactor(server, config)
  register_plan_documentation(server, config)
  register_plan_reconcile(server, config)
  register_plan_solid(server, config)
  register_plan_unwrap(server, config)
  register_plan_readme(server, config)
  server
}

// ── JSON extraction helpers (shared with serve/api_handlers.mbt pattern) ──

///|
fn json_string(json : Json?, key : String, default_ : String) -> String {
  match json {
    Some(Object(obj)) =>
      match obj.get(key) {
        Some(String(s)) => s
        _ => default_
      }
    _ => default_
  }
}

///|
fn json_double(json : Json?, key : String, default_ : Double) -> Double {
  match json {
    Some(Object(obj)) =>
      match obj.get(key) {
        Some(Number(n, ..)) => n
        _ => default_
      }
    _ => default_
  }
}

///|
fn json_string_array(json : Json?, key : String) -> Array[String] {
  match json {
    Some(Object(obj)) =>
      match obj.get(key) {
        Some(Array(arr)) => {
          let result : Array[String] = []
          for item in arr {
            if item is String(s) {
              result.push(s)
            }
          }
          result
        }
        _ => []
      }
    _ => []
  }
}

///|
fn json_bool(json : Json?, key : String, default_ : Bool) -> Bool {
  match json {
    Some(Object(obj)) =>
      match obj.get(key) {
        Some(True) => true
        Some(False) => false
        _ => default_
      }
    _ => default_
  }
}

///|
fn validate_path(path : String) -> Bool {
  !path.contains("..")
}

// ── Tool registration functions ──

///|
fn register_explore(server : @mcp_server.McpServer, config : McpConfig) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "explore",
      description: "Analyze file similarity in directories. Returns clusters of similar files with similarity scores.",
      input_schema: {
        properties: {
          "targetDirs": @mcp_types.string_array_prop(
            "Directories to analyze (required)",
          ),
          "strategy": @mcp_types.enum_prop(
            "Comparison strategy",
            ["hybrid", "tfidf", "apted", "tsed"],
            default="tfidf",
          ),
          "threshold": @mcp_types.number_prop(
            "Similarity threshold (0.0-1.0)",
            default="0.5",
          ),
          "includes": @mcp_types.string_array_prop("Include file glob patterns"),
          "excludes": @mcp_types.string_array_prop("Exclude file glob patterns"),
        },
        required: ["targetDirs"],
      },
    },
    fn(params) {
      let target_dirs = json_string_array(params, "targetDirs")
      if target_dirs.length() == 0 {
        return @mcp_types.error_result("targetDirs is required")
      }
      for dir in target_dirs {
        if !validate_path(dir) {
          return @mcp_types.error_result("Invalid path: " + dir)
        }
      }
      let explore_config : @explore_cli.ExploreConfig = {
        target_dirs,
        format: "json",
        strategy: json_string(params, "strategy", "tfidf"),
        threshold: json_double(params, "threshold", 0.5),
        fdr: json_double(params, "fdr", 0.0),
        extensions: [],
        includes: json_string_array(params, "includes"),
        excludes: json_string_array(params, "excludes"),
        specs_dir,
      }
      match @explore_cli.run_to_json(explore_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_doc_graph(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "doc_graph",
      description: "Generate dependency graph for source directories. Supports mermaid, json, and codegraph formats.",
      input_schema: {
        properties: {
          "inputPaths": @mcp_types.string_array_prop(
            "Source directories to analyze (required)",
          ),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["mermaid", "json", "codegraph"],
            default="mermaid",
          ),
          "title": @mcp_types.string_prop(
            "Graph title",
            default="Module Dependencies",
          ),
        },
        required: ["inputPaths"],
      },
    },
    fn(params) {
      let input_paths = json_string_array(params, "inputPaths")
      if input_paths.length() == 0 {
        return @mcp_types.error_result("inputPaths is required")
      }
      for p in input_paths {
        if !validate_path(p) {
          return @mcp_types.error_result("Invalid path: " + p)
        }
      }
      let graph_config : @doc_graph_cli.GraphConfig = {
        output: "",
        specs_dir,
        title: json_string(params, "title", "Module Dependencies"),
        format: json_string(params, "format", "mermaid"),
        input_paths,
      }
      match @doc_graph_cli.run_to_string(graph_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_kgf_tokens(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "kgf_tokens",
      description: "Tokenize a source file using KGF specs. Returns token stream as JSON.",
      input_schema: {
        properties: {
          "file": @mcp_types.string_prop("File path to tokenize (required)"),
          "spec": @mcp_types.string_prop(
            "KGF spec name (auto-detected from extension if empty)",
          ),
        },
        required: ["file"],
      },
    },
    fn(params) {
      let file = json_string(params, "file", "")
      if file.length() == 0 || !validate_path(file) {
        return @mcp_types.error_result("Valid file path required")
      }
      let spec = json_string(params, "spec", "")
      match @kgf_cli.tokenize_json(file, spec, specs_dir) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("Failed to tokenize file")
      }
    },
  )
}

///|
fn register_kgf_edges(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "kgf_edges",
      description: "Extract dependency edges from a source file using KGF specs. Returns edges as JSON.",
      input_schema: {
        properties: {
          "file": @mcp_types.string_prop("File path to analyze (required)"),
          "spec": @mcp_types.string_prop(
            "KGF spec name (auto-detected from extension if empty)",
          ),
        },
        required: ["file"],
      },
    },
    fn(params) {
      let file = json_string(params, "file", "")
      if file.length() == 0 || !validate_path(file) {
        return @mcp_types.error_result("Valid file path required")
      }
      let spec = json_string(params, "spec", "")
      match @kgf_cli.edges_json(file, spec, specs_dir) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("Failed to extract edges")
      }
    },
  )
}

///|
fn register_plan_refactor(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_refactor",
      description: "Generate refactoring plan from code similarity analysis. Finds duplicate code blocks and suggests consolidation.",
      input_schema: {
        properties: {
          "targetDir": @mcp_types.string_prop("Directory to analyze (required)"),
          "threshold": @mcp_types.number_prop(
            "Similarity threshold (0.0-1.0)",
            default="0.7",
          ),
          "strategy": @mcp_types.enum_prop(
            "Comparison strategy",
            ["hybrid", "tfidf", "apted", "tsed"],
            default="hybrid",
          ),
          "includes": @mcp_types.string_array_prop("Include file glob patterns"),
          "excludes": @mcp_types.string_array_prop("Exclude file glob patterns"),
          "style": @mcp_types.enum_prop(
            "Output style",
            ["raw", "github"],
            default="raw",
          ),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["md", "json"],
            default="md",
          ),
          "projectName": @mcp_types.string_prop("Project name for report"),
        },
        required: ["targetDir"],
      },
    },
    fn(params) {
      let target_dir = json_string(params, "targetDir", "")
      if target_dir.length() == 0 || !validate_path(target_dir) {
        return @mcp_types.error_result("Valid targetDir required")
      }
      let refactor_config : @plan_refactor.RefactorPlanConfig = {
        target_dir,
        threshold: json_double(params, "threshold", 0.7),
        fdr: json_double(params, "fdr", 0.0),
        strategy: json_string(params, "strategy", "hybrid"),
        includes: json_string_array(params, "includes"),
        excludes: json_string_array(params, "excludes"),
        output: "",
        format: json_string(params, "format", "md"),
        style: json_string(params, "style", "raw"),
        project_name: json_string(params, "projectName", ""),
        specs_dir,
      }
      match @plan_refactor.run_to_string(refactor_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_plan_documentation(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_documentation",
      description: "Analyze documentation coverage. Shows which public declarations lack doc comments.",
      input_schema: {
        properties: {
          "targetDir": @mcp_types.string_prop("Directory to analyze (required)"),
          "style": @mcp_types.enum_prop(
            "Report style",
            ["full", "coverage", "summary"],
            default="full",
          ),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["md", "json"],
            default="md",
          ),
          "projectName": @mcp_types.string_prop("Project name for report"),
        },
        required: ["targetDir"],
      },
    },
    fn(params) {
      let target_dir = json_string(params, "targetDir", "")
      if target_dir.length() == 0 || !validate_path(target_dir) {
        return @mcp_types.error_result("Valid targetDir required")
      }
      let doc_config : @plan_doc.DocPlanConfig = {
        target_dir,
        output: "",
        style: json_string(params, "style", "full"),
        format: json_string(params, "format", "md"),
        template: json_string(params, "template", ""),
        project_name: json_string(params, "projectName", ""),
        specs_dir,
      }
      match @plan_doc.run_to_string(doc_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_plan_reconcile(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_reconcile",
      description: "Detect drift between implementation and documentation. Finds stale or outdated docs.",
      input_schema: {
        properties: {
          "targetDir": @mcp_types.string_prop("Directory to analyze (required)"),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["json", "md"],
            default="json",
          ),
        },
        required: ["targetDir"],
      },
    },
    async fn(params) {
      let target_dir = json_string(params, "targetDir", "")
      if target_dir.length() == 0 || !validate_path(target_dir) {
        return @mcp_types.error_result("Valid targetDir required")
      }
      let reconcile_config : @plan_reconcile.ReconcileConfig = {
        ..@plan_reconcile.ReconcileConfig::default(),
        target_dir,
        format: json_string(params, "format", "json"),
        specs_dir,
      }
      match @plan_reconcile.run_to_string(reconcile_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_plan_solid(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_solid",
      description: "Plan cross-package code extraction (solidification). Finds common code across multiple directories.",
      input_schema: {
        properties: {
          "fromDirs": @mcp_types.string_array_prop(
            "Source directories (at least 2 required)",
          ),
          "toDir": @mcp_types.string_prop("Target directory for shared code"),
          "rules": @mcp_types.string_array_prop("Inline extraction rules"),
          "threshold": @mcp_types.number_prop(
            "Similarity threshold (0.0-1.0)",
            default="0.9",
          ),
          "strategy": @mcp_types.enum_prop(
            "Comparison strategy",
            ["tfidf", "hybrid", "apted"],
            default="tfidf",
          ),
          "includes": @mcp_types.string_array_prop("Include file glob patterns"),
          "excludes": @mcp_types.string_array_prop("Exclude file glob patterns"),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["md", "json"],
            default="md",
          ),
        },
        required: ["fromDirs"],
      },
    },
    fn(params) {
      let from_dirs = json_string_array(params, "fromDirs")
      if from_dirs.length() < 2 {
        return @mcp_types.error_result("At least 2 fromDirs required")
      }
      for dir in from_dirs {
        if !validate_path(dir) {
          return @mcp_types.error_result("Invalid path: " + dir)
        }
      }
      let solid_config : @plan_solid.SolidConfig = {
        from_dirs,
        to_dir: json_string(params, "toDir", ""),
        rules_file: "",
        inline_rules: json_string_array(params, "rules"),
        threshold: json_double(params, "threshold", 0.9),
        strategy: json_string(params, "strategy", "tfidf"),
        includes: json_string_array(params, "includes"),
        excludes: json_string_array(params, "excludes"),
        output: "",
        format: json_string(params, "format", "md"),
        specs_dir,
      }
      match @plan_solid.run_to_string(solid_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_plan_unwrap(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_unwrap",
      description: "Detect unnecessary wrapper functions that simply delegate to another function.",
      input_schema: {
        properties: {
          "targetDir": @mcp_types.string_prop("Directory to analyze (required)"),
          "includes": @mcp_types.string_array_prop("Include file glob patterns"),
          "excludes": @mcp_types.string_array_prop("Exclude file glob patterns"),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["md", "json"],
            default="md",
          ),
          "includeSelf": @mcp_types.bool_prop(
            "Include self-referencing wrappers",
          ),
          "includeBare": @mcp_types.bool_prop("Include bare-name wrappers"),
        },
        required: ["targetDir"],
      },
    },
    fn(params) {
      let target_dir = json_string(params, "targetDir", "")
      if target_dir.length() == 0 || !validate_path(target_dir) {
        return @mcp_types.error_result("Valid targetDir required")
      }
      let unwrap_config : @plan_unwrap.UnwrapConfig = {
        target_dir,
        includes: json_string_array(params, "includes"),
        excludes: json_string_array(params, "excludes"),
        output: "",
        format: json_string(params, "format", "md"),
        include_self: json_bool(params, "includeSelf", false),
        include_bare: json_bool(params, "includeBare", false),
        mode: "report",
        specs_dir,
      }
      match @plan_unwrap.run_to_string(unwrap_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}

///|
fn register_plan_readme(
  server : @mcp_server.McpServer,
  config : McpConfig,
) -> Unit {
  let specs_dir = config.specs_dir
  server.register_tool(
    {
      name: "plan_readme",
      description: "Generate README documentation writing plans and tasks for packages.",
      input_schema: {
        properties: {
          "targetDir": @mcp_types.string_prop("Directory to analyze (required)"),
          "template": @mcp_types.string_prop(
            "README template content (required)",
          ),
          "format": @mcp_types.enum_prop(
            "Output format",
            ["md", "json"],
            default="md",
          ),
          "plansDir": @mcp_types.string_prop(
            "Directory for plan files (auto-detected if empty)",
          ),
        },
        required: ["targetDir", "template"],
      },
    },
    fn(params) {
      let target_dir = json_string(params, "targetDir", ".")
      if !validate_path(target_dir) {
        return @mcp_types.error_result("Invalid path")
      }
      let template = json_string(params, "template", "")
      if template.length() == 0 {
        return @mcp_types.error_result("template is required")
      }
      let readme_config : @plan_readme.ReadmePlanConfig = {
        target_dir,
        output: "",
        format: json_string(params, "format", "md"),
        specs_dir,
        template,
        plans_dir: {
          let v = json_string(params, "plansDir", "")
          if v.length() > 0 {
            v
          } else {
            match @config.resolve_project_indexion_dir(target_dir, "plans") {
              Some(dir) => dir
              None => return @mcp_types.error_result("Project root not found")
            }
          }
        },
      }
      match @plan_readme.run_to_string(readme_config) {
        Some(result) => @mcp_types.text_result(result)
        None => @mcp_types.error_result("No results")
      }
    },
  )
}
