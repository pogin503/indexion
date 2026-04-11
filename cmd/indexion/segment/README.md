# indexion segment

Split text into contextual segments.

## Overview

Splits a text file into segments using divergence-based, TF-IDF, or punctuation strategies. Designed for RAG/embedding pipelines and sub-document similarity analysis.

## Usage

```bash
indexion segment [options] <input-file> <output-dir>
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--strategy=NAME` | Strategy: `window`, `tfidf`, `punctuation` | `window` |
| `--adaptive` | Use adaptive threshold mode (default) | true |
| `--hybrid` | Use NCD+TF-IDF hybrid mode (best quality) | false |
| `--min-size=INT` | Minimum segment size in chars | `100` |
| `--max-size=INT` | Maximum segment size in chars | `2000` |
| `--target-size=INT` | Target segment size in chars | `500` |
| `--threshold=FLOAT` | Divergence threshold | `0.42` |
| `--window-size=INT` | Window size for divergence | `3` |
| `--ncd-weight=FLOAT` | NCD weight in hybrid mode | `0.5` |
| `--tfidf-weight=FLOAT` | TF-IDF weight in hybrid mode | `0.5` |
| `--prefix=TEXT` | Output file prefix | `segment` |

## Examples

```bash
# Default window strategy
indexion segment document.txt output/

# Hybrid mode (best quality)
indexion segment --hybrid document.txt output/

# Custom segment sizes
indexion segment --min-size=200 --max-size=1000 --target-size=400 doc.txt out/
```
