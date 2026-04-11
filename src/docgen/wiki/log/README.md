# log

## API

- **`load`** (Function) — Load the wiki log from the given wiki directory.
- **`WikiLog`** (Struct) — The full wiki log, wrapping an array of entries.
- **`WikiLogEntry`** (Struct) — A single log entry recording a wiki operation.
- **`to_display`** (Function) — Render a log entry as a human-readable line.
- **`tail`** (Function) — Get the last N entries (most recent last).
- **`save`** (Function) — Save the log to the given wiki directory.
- **`append`** (Function) — Append a new entry to the log.
- **`length`** (Function) — Get total number of entries.
- **`new`** (Function) —
