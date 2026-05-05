export type TodoStatus = "open" | "done";

export interface Todo {
  id: number;
  title: string;
  status: TodoStatus;
  createdAt: string;
}

export interface TodoStore {
  nextId: number;
  items: Todo[];
}

export function emptyStore(): TodoStore {
  return { nextId: 1, items: [] };
}
