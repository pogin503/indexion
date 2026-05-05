# todo-app / cli / typescript

Simple CLI todo application in TypeScript.

## Layout

```
src/
  types.ts     — Todo / TodoStatus / TodoStore + emptyStore()
  service.ts   — pure operations: add, setStatus, remove, list, find
  storage.ts   — JSON file persistence (node:fs)
  format.ts    — pretty-printers
  cli.ts       — argv → CliResult dispatcher
  main.ts      — entry point (process.argv / stdout / exit)
```

## Surface

```
todo list [open|done|all]
todo add <title...>
todo done <id>
todo reopen <id>
todo remove <id>
todo help
```

State persists to `$TODO_STORE` (default `.todo-store.json`) as
`{ nextId: number, items: Todo[] }`.
