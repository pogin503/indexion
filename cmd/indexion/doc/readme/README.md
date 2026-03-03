# indexion doc readme

Extract documentation from source files and generate README files.

## Overview

Extracts `///` documentation comments from MoonBit source files and
outputs them in various formats. Supports flexible package discovery
with include/exclude patterns.

## Usage

```bash
indexion doc readme [options] [paths...]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--include=PATTERN` | Include packages matching glob (repeatable) | all |
| `--exclude=PATTERN` | Exclude packages matching glob (repeatable) | none |
| `--recursive` | Scan directories recursively | true |
| `--no-recursive` | Do not scan recursively | |
| `--format=FORMAT` | Output: `markdown`, `json`, `raw` | markdown |
| `--output=FILE` | Output to file | stdout |
| `--per-package` | Generate README.md per package | false |
| `--root` | Generate root README.md | false |
| `--no-packages` | Skip individual package output | false |

## Examples

```bash
# Extract docs from current directory
indexion doc readme

# Extract from specific path with JSON output
indexion doc readme --format=json src/

# Filter packages
indexion doc readme --include="cmd/*" --exclude="*test*"

# Generate per-package READMEs (legacy behavior)
indexion doc readme --per-package --root
```
