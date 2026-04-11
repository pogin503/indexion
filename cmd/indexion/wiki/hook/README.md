# hook

## API

- **`find_marker_range`** (Function) — Locate the start/end character positions of the indexion section.
- **`shell_token_defs`** (Function) — Token definitions for the KGF shell lexer — mirrors `kgfs/dsl/shell.kgf`.
- **`remove_hook_section`** (Function) — Remove the indexion-managed section from `content` using the KGF shell
- **`build_post_checkout_script`** (Function) — Runs `indexion wiki pages ingest` only on branch switches (not file checkouts).
- **`section_installed`** (Function) — Return true if `content` already contains the indexion start marker.
- **`shell_comment_tokens`** (Function) — Tokenize `content` as a POSIX shell script using the KGF shell lexer
- **`uninstall_hook`** (Function) — Remove the indexion-managed section from a hook file.
- **`is_shebang_only`** (Function) — Return true if `content` has no meaningful content beyond an optional shebang.
- **`hook_status`** (Function) — Return "installed" or "not installed" for a hook file.
- **`build_post_commit_script`** (Function) — Runs `indexion wiki pages ingest` for every commit.
- **`uninstall_command`** (Function) — 


- **`post_checkout_hook_name`** (Function) — 


- **`command`** (Function) — 


- **`install_command`** (Function) — 


- **`post_commit_hook_name`** (Function) — 


- **`status_command`** (Function) — 


- **`install_hook`** (Function) —
