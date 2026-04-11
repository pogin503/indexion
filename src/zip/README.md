# zip

## API

- **`encode_base64`** (Function) — Encode bytes to base64 string.
- **`decode_utf8`** (Function) — Decode extracted bytes as a UTF-8 string.
- **`should_include_entry`** (Function) — Check if a ZIP entry name should be included based on glob patterns.
- **`list_entries`** (Function) — List all entries in a ZIP archive without extracting.
- **`ZipEntry`** (Struct) — Metadata for a single entry inside a ZIP archive.
- **`read_zip_bytes`** (Function) — Read a ZIP file from disk and return raw bytes.
- **`extract_all`** (Function) — Extract all entries from a ZIP archive.
- **`ZipFile`** (Struct) — A file extracted from a ZIP archive.
- **`bytes_to_fixed_array`** (Function) — Convert Bytes to FixedArray[Byte].
