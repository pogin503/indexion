import type { Todo, TodoStatus, TodoStore } from "./types.ts";

export function addTodo(store: TodoStore, title: string, now: string): TodoStore {
  const todo: Todo = {
    id: store.nextId,
    title,
    status: "open",
    createdAt: now,
  };
  return {
    nextId: store.nextId + 1,
    items: [...store.items, todo],
  };
}

export function setStatus(store: TodoStore, id: number, status: TodoStatus): TodoStore {
  const items = store.items.map((t) =>
    t.id === id ? { ...t, status } : t
  );
  return { nextId: store.nextId, items };
}

export function removeTodo(store: TodoStore, id: number): TodoStore {
  const items = store.items.filter((t) => t.id !== id);
  return { nextId: store.nextId, items };
}

export function listTodos(store: TodoStore, filter: TodoStatus | "all"): Todo[] {
  if (filter === "all") return store.items;
  return store.items.filter((t) => t.status === filter);
}

export function findTodo(store: TodoStore, id: number): Todo | null {
  for (const t of store.items) {
    if (t.id === id) return t;
  }
  return null;
}

// ===== Logic intended to exercise body-level translation =====

// Pure arithmetic + recursion. No allocations, no closures, no library calls.
// Every target language has a direct equivalent.
export function factorial(n: number): number {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

// Mutual recursion — verifies the translation preserves call graph.
export function isEven(n: number): boolean {
  if (n === 0) return true;
  return isOdd(n - 1);
}

export function isOdd(n: number): boolean {
  if (n === 0) return false;
  return isEven(n - 1);
}

// Iterative loop with mutable state — exercises for-loop translation.
export function countByStatus(store: TodoStore, status: TodoStatus): number {
  let count = 0;
  for (const t of store.items) {
    if (t.status === status) {
      count = count + 1;
    }
  }
  return count;
}

// Recursive sum — no closures, only direct recursion + indexing.
export function sumIdsFrom(store: TodoStore, index: number): number {
  if (index >= store.items.length) return 0;
  const head = store.items[index].id;
  const tail = sumIdsFrom(store, index + 1);
  return head + tail;
}

// Conditional expression with three-way result — exercises ternary
// or pattern-match translation depending on target.
export function compareStatus(a: TodoStatus, b: TodoStatus): number {
  if (a === b) return 0;
  if (a === "open") return -1;
  return 1;
}

// Higher-order function — accepts a predicate. Targets without first-class
// closures must surface this as a real conversion gap.
export function findFirst(
  store: TodoStore,
  pred: (t: Todo) => boolean,
): Todo | null {
  for (const t of store.items) {
    if (pred(t)) return t;
  }
  return null;
}
