# indexion spec align

`indexion spec align` adds SDD-oriented alignment commands under `spec`.

- `diff` detects drift categories between requirements and implementation.
- `trace` renders the requirement ↔ implementation mapping.
- `suggest` emits provenance-backed spec-wins / impl-wins guidance.
- `status` summarizes alignment state for CI usage.
- `suggest --format=tasks --agent=claude|copilot|generic` renders agent-oriented task payloads.
- `--incremental --git-base <ref>` restricts reports to files changed from a git base.
- `watch --mode <diff|trace|suggest|status>` reruns alignment when inputs change.
- trace snapshots are versioned under cache with commit-aware `history.json` entries when run inside git.

## CI

Use the generated native binary path for fail-on checks:

```sh
./scripts/indexion-native.sh spec align status \
  --fail-on=drifted \
  --specs-dir=kgfs \
  specs/ src/
```

`moon run cmd/indexion -- ...` does not currently propagate native runtime exit
status for non-zero termination, so it is not a reliable CI entrypoint for
`status --fail-on=...`.

## Dogfooding

Generate an SDD draft from the command README, then feed it back into align:

```sh
./scripts/spec-align-dogfood.sh
```

The script emits a drafted spec plus diff/trace/suggest outputs under
`.indexion/state/dogfood/spec-align/`.
By default it drafts from `cmd/indexion/spec/align/README.md` and aligns
against `cmd/indexion/spec` with `--threshold=0.05`, which is intentionally
relaxed for usage-derived drafts. It also validates that the drafted spec is
non-empty, the trace output is present, and the resulting alignment still has at
least one matched requirement so the loop fails fast when dogfooding regresses.
In addition to `suggest.md`, it emits agent-ready task handoffs
(`tasks-generic.md`, `tasks-claude.md`, `tasks-copilot.md`), a delta-spec view,
and `loop.md` summarizing the next improvement step.

SDD dialect handling is KGF-backed. `spec align` selects KGF specs that expose
`DocumentSection` semantics and consumes the resulting document facts instead of
hardcoded vendor adapters.
