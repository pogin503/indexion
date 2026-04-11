# indexion digest

Build and query a purpose-based function index.

## Overview

Extracts function-level content from the CodeGraph, computes embeddings
(TF-IDF or OpenAI), and builds a queryable vector index. Supports
incremental updates and multiple embedding providers.

## Usage

```bash
indexion digest <subcommand> [options] <directory>
```

## Subcommands

### digest build

Build or incrementally update the vector index.

```bash
indexion digest build [options] [input]
```

`input` is a source directory or `graph.json` path.

| Option | Description | Default |
|--------|-------------|---------|
| `--provider=TYPE` | Embedding provider: `auto`, `tfidf`, `openai` | `auto` |
| `--dim=INT` | Embedding dimension | `256` (tfidf) / `1536` (openai) |
| `--strategy=NAME` | vcdb strategy: `bruteforce`, `hnsw`, `ivf` | `hnsw` |
| `--index-dir=DIR` | Where to store the index | `.indexion/digest` |
| `--specs=DIR` | KGF specs directory | `kgfs` |

### digest query

Search the index by purpose. Auto-updates the index if source has changed.

```bash
indexion digest query [options] <purpose>
```

| Option | Description | Default |
|--------|-------------|---------|
| `--top-k=INT` | Number of results | `10` |
| `--min-score=FLOAT` | Minimum similarity | `0.1` |
| `--no-update` | Skip auto-update, use saved index only | false |
| `--source=DIR` | Source directory for auto-update | auto-detect |

### digest stats

Show index statistics.

```bash
indexion digest stats [options]
```

### digest status

Show index status including pending changes.

```bash
indexion digest status [options] [input]
```

### digest rebuild

Full rebuild: delete existing index and re-index from scratch.

```bash
indexion digest rebuild [options] [input]
```

## Configuration

Respects `.indexion.toml` settings (`[digest]` section):

```toml
[digest]
provider = "openai"
strategy = "hnsw"
# dim = 256
# api_key_env = "OPENAI_API_KEY"
# model = "text-embedding-3-small"
```

CLI arguments take precedence over config file settings.

## API

- **`build_digest_config`** (Function) -- Build DigestConfig from CLI config.
- **`resolve_provider`** (Function) -- Resolve embedding provider from config.
- **`build_graph_from_source`** (Function) -- Build graph from source directory.
- **`run_stats`** (Function) -- Show index statistics.
