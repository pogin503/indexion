# indexion init

Initialize indexion configuration.

## Usage

```bash
indexion init [options] [directory]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-g, --global` | Initialize global configuration | false |
| `-f, --force` | Overwrite existing files | false |

## What It Creates

- `.indexion.toml` -- Project configuration file
- `.indexionignore` -- Ignore patterns for file discovery
- Global mode creates configuration in the OS-standard config directory
