# skills -- indexion Skills

A Claude Code plugin that provides skills powered by indexion, enabling source code exploration, similarity analysis, documentation generation, and planning tools directly within the Claude Code environment. The plugin is distributed via the Claude Code marketplace as `indexion-skills`.

Skills act as structured prompts that teach Claude Code how and when to invoke specific indexion CLI commands, including usage patterns, options, and dogfooding workflows.

## Contents

```
skills/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest (name, version, description)
│   └── marketplace.json     # Marketplace registry metadata
├── skills/                  # Individual skill definitions (10 skills)
│   ├── indexion-explore/
│   ├── indexion-segment/
│   ├── indexion-kgf/
│   ├── indexion-grep/
│   ├── indexion-documentation/ # Unified: doc + plan docs/readme/reconcile
│   ├── indexion-wiki/
│   ├── indexion-plan-refactor/
│   ├── indexion-plan-solid/
│   ├── indexion-plan-unwrap/
│   └── indexion-refactor/
├── LICENSE
└── README.md
```

### Plugin Manifest

- **Name:** `indexion-skills`
- **Version:** 0.1.0
- **Skills directory:** `./skills/`

### Skill Categories

**Exploration and Analysis:**
- `indexion-explore` -- Find similar files and detect duplicates
- `indexion-segment` -- Split text into contextual segments
- `indexion-kgf` -- Inspect and debug KGF language specs
- `indexion-grep` -- KGF-aware token pattern and semantic search

**Documentation:**
- `indexion-documentation` -- Documentation lifecycle: generate graphs/READMEs, analyze coverage, plan writing tasks, detect doc drift

**Wiki:**
- `indexion-wiki` -- Build, maintain, and verify project wiki pages with indexion

**Planning:**
- `indexion-plan-refactor` -- Generate refactoring plans from similarity analysis
- `indexion-plan-solid` -- Plan common code extraction across directories
- `indexion-plan-unwrap` -- Detect and remove unnecessary wrapper functions

## Usage

```bash
# Install from marketplace
claude marketplace add trkbt10/indexion-skills
claude plugin install indexion-skills

# Prerequisites: indexion must be in PATH
curl -fsSL https://raw.githubusercontent.com/trkbt10/indexion/main/install.sh | bash
```

Once installed, skills are available as slash commands in Claude Code (e.g. `/indexion-explore`, `/indexion-wiki`, `/indexion-plan-refactor`) and are automatically triggered when the user asks relevant questions.

> Source: `skills/`
