# indexion explore

Analyze similarity across files in a directory.

## Overview

Explores a directory and calculates pairwise similarity between all files.
Useful for understanding code patterns and finding potential duplications.

## Usage

```bash
indexion explore [options] <directory>
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--format=FORMAT` | Output: `matrix`, `list`, `cluster`, `json` | matrix |
| `--strategy=NAME` | Algorithm: `tfidf`, `bm25`, `jsd`, `ncd`, `hybrid`, `apted`, `tsed` | tfidf |
| `--threshold=FLOAT` | Min similarity for list/json/cluster output | 0.5 |
| `--ext=EXT` | File extension filter (repeatable) | all |
| `--include=PATTERN` | Include files matching glob pattern (repeatable) | * |
| `--exclude=PATTERN` | Exclude files matching glob pattern (repeatable) | - |
| `--fdr=FLOAT` | FDR correction level (0=disabled, 0.05=5% false discovery rate) | 0 |
| `--specs-dir=DIR` | KGF specs directory | kgfs |

## Strategies

| Strategy | Description | Speed |
|----------|-------------|-------|
| `tfidf` (default) | TF-IDF token similarity with KGF lexer | Fast |
| `bm25` | BM25 token similarity | Fast |
| `jsd` | Jensen-Shannon Divergence | Fast |
| `ncd` | Normalized Compression Distance | Fast |
| `hybrid` | Combined NCD + TF-IDF | Fast |
| `apted` | All-Path Tree Edit Distance (function-level) | Slow |
| `tsed` | Tree Structure Edit Distance (function-level) | Slow |

## Examples

```bash
# Matrix view of all files
indexion explore src/

# List sorted by similarity
indexion explore --format=list src/

# Cluster similar files (70%+)
indexion explore --format=cluster --threshold=0.7 src/

# Filter by extension
indexion explore --ext=.mbt --ext=.kgf src/

# TypeScript only with glob filters
indexion explore --format=list --include=*.ts --include=*.tsx src/

# Exclude config noise for CLI dedup detection
indexion explore --format=list --threshold=0.7 \
  --include='*.mbt' --exclude='*moon.pkg*' cmd/indexion/

# Function-level comparison
indexion explore --strategy=apted --format=list src/
```

## Output Formats

- **matrix**: Grid showing pairwise similarity percentages
- **list**: Pairs sorted by similarity (highest first, filtered by `--threshold`)
- **cluster**: Groups of files exceeding threshold
- **json**: Machine-readable JSON output (filtered by `--threshold`)
