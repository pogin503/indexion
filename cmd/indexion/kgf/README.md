# indexion kgf

KGF spec management and inspection.

## Usage

```bash
indexion kgf [options] <command>
```

## Global Options

| Option | Description | Default |
|--------|-------------|---------|
| `--spec=NAME` | Specify KGF spec name (auto-detect if omitted) | auto |
| `--kgf-dir=DIR` | KGF specs directory | `kgfs` |

## Subcommands

| Command | Description |
|---------|-------------|
| `list` | List installed KGF specs |
| `update` | Update all specs from GitHub |
| `add` | Download and install a single spec |
| `inspect` | Full inspection (tokens, events, edges) |
| `tokens` | Show tokenization only |
| `events` | Show parse events only |
| `edges` | Show generated edges only |

## Examples

```bash
# List installed specs
indexion kgf list

# Inspect a file (auto-detect language)
indexion kgf inspect src/config/app.mbt

# Show tokens only
indexion kgf tokens --spec=moonbit src/config/app.mbt

# Show dependency edges
indexion kgf edges src/config/app.mbt
```
