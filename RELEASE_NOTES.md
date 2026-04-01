# v0.3.0

## Highlights

- **`indexion serve`** — New HTTP server command for codebase exploration, search, and wiki hosting
- **`indexion plan wiki`** — Generate wiki writing plans with stale page detection
- **Regex Engine Overhaul** — Backtracking quantifiers, lookahead, Unicode escapes
- **Async Concurrency** — Planning and Git workflows migrated to MoonBit async runtime

## New Commands

### `indexion serve`

HTTP server for codebase exploration and search. Starts on port 3741 by default.

```bash
indexion serve .
indexion serve --port=8080 --cors .
```

- REST API: digest queries, code graph, wiki pages, KGF data
- `POST /api/digest/rebuild` for live index rebuilds
- SPA static file serving with bundled web UI (explorer, 3D graph, wiki, search)
- `--cors` flag for cross-origin requests

#### `indexion serve export`

Export self-contained static site for GitHub Pages deployment.

### `indexion plan wiki`

Analyze project structure and generate wiki writing plans.

```bash
indexion plan wiki .
indexion plan wiki --format=github-issue .
```

- Proposes concept-based page structure and writing tasks
- Detects stale wiki pages when `.indexion/wiki/` exists
- Output formats: markdown, JSON, GitHub issue

## Improvements

### `digest`: `.indexion.toml` Configuration

`digest` now reads embedding settings from `.indexion.toml` / `.indexion.json`. CLI args take precedence over file config.

```toml
[digest]
provider = "openai"
dimension = 1536
```

### `plan reconcile`: Smart Caching

- Source fingerprint and config hash based caching — skips re-analysis on cache hit
- Logical review tracking for better drift detection

### Regex & PEG Engine

- Backtracking quantifiers (`*?`, `+?`, `??`)
- Positive/negative lookahead (`(?=...)`, `(?!...)`)
- Unicode escapes (`\uXXXX` including ranges)
- Expanded `\S`, `\D`, `\W` character classes
- Group end position enumeration
- Fixed PEG iterative evaluator bracket handling and semantics comment parsing

### KGF Resolver

- Exact resolution step for more precise module matching
- Improved error handling and generated resolver package types

### Async Concurrency

- Git operations and planning workflows run concurrently via MoonBit async runtime
- Removed blocking C stubs and legacy parallel module

### Ignore File Handling

- Refactored into domain-neutral gitignore-syntax parser (`src/ignorefile/`)
- Proper separation: `.gitignore` in `git/gitignore.mbt`, `.indexionignore` in `config/ignore.mbt`
- Project root detection via markers (`.git`, `.indexion`, `.indexion.toml`)

## Bug Fixes

- `discover_files` no longer excludes `.` path due to hidden-dir glob pattern
- Tests no longer pollute project `.indexion/` directory

## Internal

- Web UI packages: `packages/wiki`, `packages/api-client`, `packages/vscode-plugin`
- Test fixtures moved to `fixtures/` directory
- CI: frontend typecheck, lint, and test added to release workflow
- Version: 0.2.2 → 0.3.0
- 0 warnings, 0 errors, 1173 tests

---

# v0.2.0

## Highlights

- **Magic String Detection** — `plan refactor` now detects string literals repeated across multiple files, surfacing potential constants and SoT violations
- **Unified SoT** — All commands share the same registry loading, output handling, and CLI conventions
- **Zero Warnings** — Eliminated all 46 compiler warnings

## New Features

### `plan refactor`: Repeated String Literals

A new "Repeated String Literals" section in refactoring reports identifies hardcoded strings that appear in 2+ files. Uses KGF tokenization for language-agnostic detection.

```bash
indexion plan refactor --threshold=0.9 --include='*.mbt' src/
# → ## Repeated String Literals
#    | Value         | Files    | Occurrences |
#    | `"kgfs"`      | 13 files | 42 occurrences |
```

### `@kgf_features.load_registry_or_empty`

New convenience API that returns an empty registry instead of `None`. Eliminates `match` boilerplate at every call site.

### `@help` Package

CLI option descriptions (`--specs-dir`, `--output`, `--include`, `--exclude`) are now defined once in `cmd/indexion/help/` and shared across all commands.

### `@config.get_kgfs_install_dir()`

Single Source of Truth for the kgfs write/install path. Used by `kgf install`, `update`, and `init --global`.

## Breaking Changes

- `doc graph`: `--specs` renamed to `--specs-dir` (consistent with all other commands)
- `doc graph`: output default changed from `"-"` to `""` (behavior unchanged — both mean stdout)
- `doc readme`, `plan readme`: format default changed from `"markdown"` to `"md"` (consistent with plan commands)
- `similarity`: config field `output_format` renamed to `format`

## Improvements

- `doc graph`: defaults to `.` when no path given (previously errored)
- `doc readme`: template `{{include:path}}` now tries CWD-relative first, with warning on failure (was silent)
- `doc readme`: full symbol listing (removed "And N more symbols." truncation)
- `explore`: added `--specs-dir` option
- All `moon.pkg` files: test-only imports moved to `for "wbtest"` blocks

## Internal

- Removed duplicate utility functions: `substring_from`, `substring_config`, `trim_section_content`, `last_index_of` → replaced with `@common`/`@config` SoTs
- `@config.find_last_char` promoted to `pub`
- `TableAlign::Center`/`Right` unused variants removed
- Migrated `trkbt10/osenv` for platform config
- Version: 0.1.0 → 0.2.0
- 0 warnings, 0 errors, 1156 tests
