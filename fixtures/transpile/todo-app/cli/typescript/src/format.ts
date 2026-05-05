import type { Todo } from "./types.ts";

export function formatTodo(t: Todo): string {
  const mark = t.status === "done" ? "x" : " ";
  return `[${mark}] #${t.id} ${t.title} (${t.createdAt})`;
}

export function formatList(items: Todo[]): string {
  if (items.length === 0) return "(no todos)";
  return items.map(formatTodo).join("\n");
}
