# indexion plan refactor

Generate refactoring plan based on file similarity analysis.

## Overview

Analyzes files in a directory, identifies similar code patterns using
TF-IDF or NCD algorithms, and generates a Markdown checklist for
refactoring candidates. Detects duplicate code blocks with function-name
annotation via KGF tokenization (language-agnostic).

## Usage

```bash
indexion plan refactor [options] <directory>
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--threshold=FLOAT` | Similarity threshold (0.0-1.0) | 0.7 |
| `--strategy=NAME` | Algorithm: `hybrid`, `tfidf`, `bm25`, `jsd`, `ncd` | hybrid |
| `--fdr=FLOAT` | FDR correction level (0=disabled, 0.05=5% false discovery rate) | 0 |
| `--style=STYLE` | Output style: `raw`, `structured` | raw |
| `--format=FORMAT` | Output format: `md`, `json`, `text`, `github-issue` | md |
| `--name=NAME` | Project name (for structured style) | auto |
| `--include=PATTERN` | Include files matching glob pattern (repeatable) | * |
| `--exclude=PATTERN` | Exclude files matching glob pattern (repeatable) | - |
| `-o, --output=FILE` | Output file path | stdout |
| `--specs-dir=DIR` | KGF specs directory | kgfs |

## Examples

```bash
# Basic usage - analyze src/ with 70% threshold
indexion plan refactor src/

# Higher threshold, exclude tests
indexion plan refactor --threshold=0.85 --exclude='*_wbtest.mbt' src/

# Structured plan with phases and checklists
indexion plan refactor --style=structured --name=myproject src/

# GitHub Issue format
indexion plan refactor --format=github-issue src/

# CLI dedup detection (proven workflow)
indexion plan refactor --threshold=0.9 \
  --include='*.mbt' --exclude='*_wbtest.mbt' \
  --exclude='*moon.pkg*' --exclude='*pkg.generated*' \
  cmd/indexion/

# Output to file
indexion plan refactor --include='*.mbt' -o=refactor-plan.md src/
```

## Output

### Raw style (default)

- Configuration summary
- Grouped similar files (clustered by similarity)
- Duplicate code blocks with line numbers and function names
- Suggested shared module paths
- Action item checklist

### Structured style

- Phased refactoring plan
- Priority-ordered checklists
- Risk assessment
