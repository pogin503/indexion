# manifest

## API

- **`remove_deleted_functions`** (Function) — Remove deleted functions and return their vector IDs for cleanup.
- **`get_deleted_functions`** (Function) — Find deleted functions (in manifest but not in current units).
- **`DigestManifest`** (Struct) — DigestManifest tracks function-level indexing state.
- **`FunctionEntry`** (Struct) — Entry for a single function in the manifest.
- **`get_stale_functions`** (Function) — Find stale functions that need re-indexing.
- **`FileEntry`** (Struct) — Entry for a single file in the manifest.
- **`get_timestamp`** (Function) — Get current timestamp placeholder.
- **`to_json_string`** (Function) — Serialize manifest to JSON string.
- **`from_json_string`** (Function) — Parse manifest from JSON string.
- **`update_function`** (Function) — Update or add a function entry.
- **`get_function`** (Function) — Get function entry if exists.
- **`allocate_vector_id`** (Function) — Allocate a new vector ID.
- **`remove_function`** (Function) — Remove a function entry.
- **`get_function_ids`** (Function) — Get all function IDs.

And 9 more symbols.
