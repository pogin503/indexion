# update

## API

- **`extract_hash_from_checksum`** (Function) — Extract the hash from a checksum file line (first whitespace-delimited field).
- **`compare_versions`** (Function) — Compare two semver: returns positive if a > b, negative if a < b, 0 if equal.
- **`get_install_dir`** (Function) — Get the install directory for indexion, delegating to config SoT.
- **`parse_semver`** (Function) — Parse a version string like "0.1.0" or "v0.1.0" into Semver.
- **`extract_tag_name`** (Function) — Extract "tag_name" value from GitHub API JSON response.
- **`verify_checksum`** (Function) — Verify SHA-256 checksum of data against expected hash.
- **`to_string`** (Function) — Format update error as human-readable string.
- **`build_download_url`** (Function) — Build the download URL for a release asset.
- **`build_checksum_url`** (Function) — Build the checksum URL for a release asset.
- **`Semver`** (Struct) — Parsed semver components.

And 29 more symbols.
