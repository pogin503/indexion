# indexion perf

Performance benchmark commands.

## Usage

```bash
indexion perf <command>
```

## Subcommands

### perf kgf

Run KGF parse benchmark.

```bash
indexion perf kgf [options]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--spec=FILE` | KGF spec file | `kgfs/moonbit.kgf` |
| `--input=FILE` | Input source file | `src/docgen/build/pipeline.mbt` |
| `--iterations=INT` | Iterations per benchmark | `20` |
| `--warmup=INT` | Warmup iterations | `3` |
