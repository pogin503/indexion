# tests/integration/cross-package-resolution

Snapshot-based integration tests that pin the observable output of
`indexion doc graph --format=codegraph` for each fixture project under
`fixtures/project/`.

## What these tests guard

1. **`moduleDependsOn` edge set** — every cross-package import that the
   analyzer produces, including canonicalization back to internal paths
   for workspace/internal packages.
2. **Structural completeness** — every edge of a built-in `EdgeKind`
   (`declares`, `moduleDependsOn`, `calls`, `references`, `imports`,
   `extends`, `implements`, `circularDependency`) must have both endpoints
   registered as modules or symbols in the final serialized graph. This is
   the invariant downstream consumers (the React viewer, IDE plugins) rely
   on when rendering the graph.

Custom edge kinds emitted by KGF specs for metadata (`projectName`,
`projectKeyword`, `packageVersion`, …) are intentionally excluded from the
structural completeness check because their `to` fields carry free-form
values like keywords or version strings, not module identities.

## Coverage

| Snapshot | Fixture | Ecosystem / constructs exercised |
| --- | --- | --- |
| `python.snapshot.json` | `fixtures/project/python` | pyproject.toml, src-layout, sub-packages, `from .X import Y` |
| `cargo.snapshot.json` | `fixtures/project/cargo` | Cargo single-crate, `use crate::..`, extern crates via Cargo.toml deps |
| `cargo-workspace.snapshot.json` | `fixtures/project/cargo-workspace` | Cargo `[workspace]` with multiple `crates/*` and path deps |
| `go.snapshot.json` | `fixtures/project/go` | go.mod modules, internal sub-packages, stdlib-shaped paths |
| `ruby.snapshot.json` | `fixtures/project/ruby` | Gemfile + `require_relative` module layout |
| `php.snapshot.json` | `fixtures/project/php` | composer.json PSR-4, `use` namespaces |
| `swift.snapshot.json` | `fixtures/project/swift` | Package.swift with library + executable targets |
| `csharp.snapshot.json` | `fixtures/project/csharp` | .csproj with PackageReference, multi-file namespaces |
| `maven.snapshot.json` | `fixtures/project/maven` | pom.xml + Spring Boot layout |
| `gradle.snapshot.json` | `fixtures/project/gradle` | build.gradle.kts + Kotlin sources |
| `deno.snapshot.json` | `fixtures/project/deno` | deno.json imports + relative URLs |
| `npm.snapshot.json` | `fixtures/project/npm` | package.json single package + TS relative imports |
| `npm-circular.snapshot.json` | `fixtures/project/npm-circular` | Intentional circular TS import cycle |
| `npm-monorepo.snapshot.json` | `fixtures/project/npm-monorepo` | npm workspace with multiple packages + cross-workspace imports |
| `typescript-reconcile.snapshot.json` | `fixtures/project/typescript-reconcile` | TS project with internal-only imports (no cross-package deps) |
| `moonbit-with-web.snapshot.json` | `fixtures/project/moonbit-with-web` | MoonBit core + embedded npm web project |
| `moonbit.snapshot.json` | `fixtures/project/moonbit` | `moon.pkg` alias capture, source-file `@alias` scan, `projectSourceDir` resolution |
| `vcpkg.snapshot.json` | `fixtures/project/vcpkg` | vcpkg.json manifest + C++ sources (deps only; source-level `#include` not yet parsed) |

## Running

```bash
moon test --target native tests/integration/cross-package-resolution
```

Each test analyzes its fixture and compares the normalized snapshot
(`snapshot_of(graph)`) against the committed JSON file.

## Updating snapshots

When the analyzer's behaviour changes legitimately (new edge kinds, smarter
canonicalization, grammar improvements), regenerate the snapshots:

```bash
INDEXION_UPDATE_SNAPSHOTS=1 moon test --target native tests/integration/cross-package-resolution
```

Review the resulting diff carefully — any change is a user-visible change
to the codegraph output that downstream consumers will see.

## Adding a new fixture

1. Add the fixture directory under `fixtures/project/<name>/` with a
   manifest file and representative source files (imports, sub-packages,
   external dependency references).
2. Create `<name>_test.mbt`:

   ```moonbit
   test "snapshot: fixtures/project/<name>" {
     let graph = analyze_fixture("fixtures/project/<name>")
     assert_snapshot_matches(
       "tests/integration/cross-package-resolution/<name>.snapshot.json",
       snapshot_of(graph),
     )
     assert_eq(count_unresolved_structural(graph), 0)
   }
   ```

3. Run with `INDEXION_UPDATE_SNAPSHOTS=1` to generate the initial snapshot.
4. Commit both the fixture files and the snapshot.

## Known limitations (will become apparent as snapshot diffs when fixed)

- Python `from .submod import X` and `from ..pkg import Y` currently fall
  back to `pip:` prefix rather than canonicalizing to the internal
  `src/<pkg>/submod/__init__.py` path. The Rust-style crate/self/super
  progressive-resolve infrastructure is in place but Python semantics
  haven't adopted it yet.
- Rust `use` statements emit one edge per `use` and do not yet fan out
  multi-item `use foo::{a, b, c}` groups. The first item's resolution
  stands for the group.
- C/C++ (`#include`) is not parsed; only the vcpkg/CMake manifest deps
  surface in the graph.
- Duplicate edges sometimes appear (same `(from, to)` pair recorded twice)
  when grammar alternatives both fire on the same input. These are
  deterministic and locked into the snapshot; collapsing them is a
  follow-up.
