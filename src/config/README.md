# config

## API

- **`get_platform_asset_name`** (Function) — Get the platform asset name for release downloads.
- **`find_nearest_marker_dir`** (Function) — Find the nearest directory containing any configured project marker pattern.
- **`get_install_dir`** (Function) — Get the indexion install directory.
- **`load_global_config`** (Function) — Load global configuration from OS-standard config directory.
- **`merge_global_into_file`** (Function) — Merge global config into file config.
- **`resolve_reconcile_specs_dir`** (Function) — Resolve the KGF specs directory for reconcile, using explicit path or auto-detection.
- **`resolve_config_path_value`** (Function) — Resolve a path value using config directory when present, otherwise target root.
- **`ProjectFileConfig`** (Struct) — Project configuration with inherit_global flag and command-specific settings.
- **`resolve_effective_reconcile_config`** (Function) — Resolve effective reconcile config with merged values and provenance.
- **`is_empty_dir`** (Function) — Check if a directory is empty (contains no files or subdirectories).
- **`load_project_config`** (Function) — Load project configuration from .indexion.toml or .indexion.json.
- **`find_indexion_config_path`** (Function) — Find `.indexion.toml` or `.indexion.json` for a target directory.
- **`default`** (Function) — Create default project config with inherit_globalance enabled.
- **`EffectiveReconcileConfig`** (Struct) — Effective reconcile config with merged values and provenance.
- **`default_reconcile_index_dir`** (Function) — Default cache/index directory for `indexion plan reconcile`.

And 154 more symbols.
