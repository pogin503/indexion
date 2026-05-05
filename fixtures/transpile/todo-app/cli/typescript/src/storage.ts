import { readFileSync, writeFileSync, existsSync } from "node:fs";
import type { TodoStore } from "./types.ts";
import { emptyStore } from "./types.ts";

export function loadStore(path: string): TodoStore {
  if (!existsSync(path)) return emptyStore();
  const raw = readFileSync(path, "utf-8");
  if (raw.trim() === "") return emptyStore();
  return JSON.parse(raw) as TodoStore;
}

export function saveStore(path: string, store: TodoStore): void {
  const json = JSON.stringify(store, null, 2);
  writeFileSync(path, json, "utf-8");
}
