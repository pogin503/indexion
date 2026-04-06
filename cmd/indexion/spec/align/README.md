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

SDD dialect handling is KGF-backed. `spec align` selects KGF specs with
`sdd_*` features and reads their structure from KGF sections instead of
hardcoded vendor adapters.
