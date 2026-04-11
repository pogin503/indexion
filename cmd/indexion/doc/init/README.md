# indexion doc init

Initialize documentation template structure.

## Usage

```bash
indexion doc init [options] [directory]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --force` | Overwrite existing files | false |
| `--specs-dir=DIR` | KGF specs directory | `kgfs` |

## What It Creates

Creates `.indexion/state/templates/readme.md` with `{{include:...}}` placeholder directives for use with `indexion doc readme --template=...` and `indexion plan readme --template=...`.
