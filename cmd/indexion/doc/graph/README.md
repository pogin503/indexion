# indexion doc graph

Generate dependency graph in various formats.

## Usage

```bash
indexion doc graph [options] [files...]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--format=FORMAT` | Output format: `mermaid`, `json`, `dot`, `d2`, `text` | `mermaid` |
| `--title=TEXT` | Diagram title | `Module Dependencies` |
| `--output=FILE` | Output file path | stdout |
| `--specs-dir=DIR` | KGF specs directory | `kgfs` |

## Examples

```bash
# Mermaid format (default)
indexion doc graph src/

# Graphviz DOT
indexion doc graph --format=dot src/

# D2 diagram
indexion doc graph --format=d2 --output=deps.d2 src/
```
