# ingest

## API

- **`tasks_to_plan_document`** (Function) — Convert ingest tasks to a PlanDocument for rendering.
- **`IngestManifest`** (Struct) — The full ingest manifest, persisted between runs.
- **`load_manifest`** (Function) — Load the ingest manifest from a wiki directory.
- **`save_manifest`** (Function) — Save the ingest manifest to a wiki directory.
- **`IngestResult`** (Struct) — The result of an ingest analysis.
- **`IngestTask`** (Struct) — A task for updating a wiki page.
- **`PageSourceState`** (Struct) — Per-page source state tracking.
- **`SourceChange`** (Struct) — A single source file change.
