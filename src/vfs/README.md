# vfs

## API

- **`extract_text_content`** (Function) — Extract concatenated text content from an archive file.
- **`extract_text_entries`** (Function) — Extract individual text entries from an archive as (virtual_path, content) pairs.
- **`expand_archive`** (Function) — Expand a single archive file into VFSEntry items.
- **`is_virtual_path`** (Function) — Check if a path is a virtual (archive-internal) path.
- **`parse_virtual_path`** (Function) — Parse a virtual path into (archive_path, inner_path) if it contains the archive separator.
- **`inner_path`** (Function) — Extract just the inner path portion from a virtual path.
- **`ArchiveSpec`** (Struct) — Configuration for archive expansion.
- **`VFSEntry`** (Struct) — A virtual file entry — either a real file or an entry inside an archive.
