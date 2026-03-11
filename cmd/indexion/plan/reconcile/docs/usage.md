## Usage

```bash
indexion plan reconcile [options] <directory>
```

Common examples:

```bash
# Scan the current project and print JSON
indexion plan reconcile .

# Render a human-readable report
indexion plan reconcile --format=md cmd/indexion/plan/reconcile

# Restrict document inputs
indexion plan reconcile \
  --doc='docs/**/*.md' \
  --doc='spec/**/*.toml' \
  --doc-spec=markdown \
  --doc-spec=toml \
  .

# Apply logical review decisions from a JSON file
indexion plan reconcile \
  --review-results=.indexion/reconcile/reviews.json \
  .
```

Main CLI options:

| Option | Purpose | Default |
|--------|---------|---------|
| `--format=json\|md\|github-issue` | Select report renderer | `json` |
| `--output=FILE`, `-o=` | Write report to a file | stdout |
| `--specs=DIR` | Override KGF spec directory | auto-detect |
| `--index-dir=DIR` | Override reconcile cache directory | `.indexion/reconcile` |
| `--config=FILE` | Load explicit `.indexion.toml` or `.json` | auto-discover |
| `--doc=GLOB` | Limit document paths, repeatable | all detectable docs |
| `--doc-spec=NAME` | Limit document specs, repeatable | all detected specs |
| `--threshold-seconds=N` | Tolerated time skew before drift | `60` |
| `--max-candidates=N` | Max report candidates | `200` |
| `--no-file-fallback` | Disable basename fallback matching | off |
| `--mtime-only` | Ignore git timestamps and use mtimes only | off |
| `--logical-review=queue\|off` | Enable or disable logical review queueing | `queue` |

Best practice is to start with JSON output, inspect candidate IDs and review keys, and then switch to Markdown or GitHub Issue rendering for human workflows.
