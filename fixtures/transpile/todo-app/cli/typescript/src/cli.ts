import { loadStore, saveStore } from "./storage.ts";
import { addTodo, listTodos, removeTodo, setStatus, findTodo } from "./service.ts";
import { formatList, formatTodo } from "./format.ts";
import type { TodoStatus } from "./types.ts";

export interface CliResult {
  exitCode: number;
  output: string;
}

export function runCli(argv: string[], storePath: string, now: string): CliResult {
  const cmd = argv[0] ?? "help";
  const store = loadStore(storePath);

  if (cmd === "list") {
    const filterArg = argv[1] ?? "all";
    const filter: TodoStatus | "all" =
      filterArg === "open" || filterArg === "done" ? filterArg : "all";
    return { exitCode: 0, output: formatList(listTodos(store, filter)) };
  }

  if (cmd === "add") {
    const title = argv.slice(1).join(" ").trim();
    if (title === "") {
      return { exitCode: 2, output: "error: title is required" };
    }
    const next = addTodo(store, title, now);
    saveStore(storePath, next);
    const created = next.items[next.items.length - 1];
    return { exitCode: 0, output: `added: ${formatTodo(created)}` };
  }

  if (cmd === "done" || cmd === "reopen") {
    const id = parseInt(argv[1] ?? "", 10);
    if (Number.isNaN(id)) {
      return { exitCode: 2, output: "error: id is required" };
    }
    const target = findTodo(store, id);
    if (target === null) {
      return { exitCode: 1, output: `error: not found: ${id}` };
    }
    const status: TodoStatus = cmd === "done" ? "done" : "open";
    const next = setStatus(store, id, status);
    saveStore(storePath, next);
    return { exitCode: 0, output: `${cmd}: #${id}` };
  }

  if (cmd === "remove") {
    const id = parseInt(argv[1] ?? "", 10);
    if (Number.isNaN(id)) {
      return { exitCode: 2, output: "error: id is required" };
    }
    const target = findTodo(store, id);
    if (target === null) {
      return { exitCode: 1, output: `error: not found: ${id}` };
    }
    saveStore(storePath, removeTodo(store, id));
    return { exitCode: 0, output: `removed: #${id}` };
  }

  if (cmd === "help") {
    const lines = [
      "usage: todo <command> [args]",
      "  list [open|done|all]   list todos",
      "  add <title...>         add a new todo",
      "  done <id>              mark as done",
      "  reopen <id>            mark as open",
      "  remove <id>            delete a todo",
      "  help                   show this help",
    ];
    return { exitCode: 0, output: lines.join("\n") };
  }

  return { exitCode: 2, output: `error: unknown command: ${cmd}` };
}
