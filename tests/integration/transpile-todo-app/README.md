# transpile-todo-app integration test

MoonBit integration test for the lift/lower transpile architecture
(`src/kgf/transpile/`) plus the per-language specs at `kgf-transpile/`.

The test exercises a TypeScript todo-app fixture against multiple target
languages and snapshots the resulting drift signals.

## What's tested

- The engine accepts every (source, target) pair without per-pair logic.
- For each emitted file, the count and *kind* of `@@UNRESOLVED@@<kind>`
  markers in the lowered code matches the snapshot.
- The lifted IR rule histogram matches — i.e. the lift specs project
  KGF events into canonical IR rules (IRStruct, IRFn, IREnum, ...).
- Every observed unresolved kind is classified (`KGF` / `MAPPING` /
  `ENGINE` / `CONVERSION`) so the snapshot diff attributes any future
  drift to one of those four causes.

## Layout

```
runner.mbt                     # build_target_snapshot, kind_diagnosis
moonbit_target_test.mbt        # snapshot: ts → moonbit
python_target_test.mbt         # snapshot: ts → python
rust_target_test.mbt           # snapshot: ts → rust
moonbit.snapshot.json          # locked output for the ts → moonbit pair
python.snapshot.json           # locked output for the ts → python pair
rust.snapshot.json             # locked output for the ts → rust pair
```

The TypeScript SoT lives at `fixtures/transpile/todo-app/cli/typescript/src/`.
Per-language transpile specs live at `kgf-transpile/<lang>.json`.

## Running

```bash
moon test --target native tests/integration/transpile-todo-app
```

To regenerate snapshots after a deliberate change:

```bash
INDEXION_UPDATE_SNAPSHOTS=1 moon test --target native tests/integration/transpile-todo-app
```

## Adding a target

Drop `kgf-transpile/<new-lang>.json` (with at least a `lower` section),
add `<new-lang>_target_test.mbt`:

```moonbit
test "snapshot: ts todo-app -> <new-lang>" {
  run_target_snapshot("<new-lang>")
}
```

Run the test with `INDEXION_UPDATE_SNAPSHOTS=1` to lock in the snapshot.
No engine or runner changes needed.

## Diagnosis classes

The runner classifies each observed `@@UNRESOLVED@@<kind>` into one of:

| Class | Meaning | Example |
|-------|---------|---------|
| `KGF` | The source language's KGF spec doesn't extract the structure | TypeScript KGF doesn't label FunctionDecl return type |
| `MAPPING` | KGF extracts it but transpile-spec format can't reference it | InterfaceDecl id is on sibling InterfaceHeader; spec has no `id_from` |
| `ENGINE` | Engine code can't represent the operation | Token-level interleaving across events |
| `CONVERSION` | Source feature has no canonical equivalent | TS `any` / `unknown` / arbitrary expressions |

The snapshot's `unresolved_diagnosis` array carries the verdict for every
kind that actually appeared. Closing each class:

- `KGF`: extend the source-language `.kgf` spec to label the missing edge.
- `MAPPING`: extend the transpile spec format with a new declarative rule
  (e.g. `id_from: <Sibling>.<label>`, `collect_inner: <Rule>`,
  `extract_text: <regex>`) and add the corresponding pass to the engine.
- `ENGINE`: extend `src/kgf/transpile/engine.mbt`.
- `CONVERSION`: not closable — these mark genuine portability gaps.

## Current diagnosis (ts todo-app fixture)

From the snapshots:

| Kind | Class | Count (mb / py / rs) |
|------|-------|---------------------|
| `return` | KGF | 12 / 0 / 12 |
| `id_text` | MAPPING | 3 / 3 / 3 |
| `fields` | MAPPING | 3 / 3 / 3 |
| `rhs` | MAPPING | 1 / 0 / 1 |

Three out of four observed kinds are MAPPING-class — pointing at the
transpile-spec format as the highest-leverage extension target. The
remaining KGF-class issue (TS function return-type labeling) is a
single-spec fix in `kgfs/typescript.kgf`.
