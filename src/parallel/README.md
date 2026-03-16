# parallel

Fork-based process parallelism for native targets.

## Overview

Runs multiple tasks in parallel using `fork()` + temp file IPC.
Each task executes in a child process and writes its result to a temp file.
The parent waits for all children and collects results.

Falls back to sequential execution on non-native targets (wasm, js).

## Usage

```moonbit
let results = @parallel.run_parallel([
  fn() { expensive_task_a() },
  fn() { expensive_task_b() },
])
// results[0] = output of task A
// results[1] = output of task B
```

## API

- `available()` — Whether fork-based parallelism is available
- `cpu_count()` — Number of available CPU cores
- `run_parallel(tasks)` — Run tasks in parallel, returns results in order
