/**
 * @file Tests for plan history storage.
 */

import { describe, it, expect } from "vitest";
import { getHistory, getHistoryForType, addHistoryEntry, clearHistory, clearHistoryForType } from "./history.ts";

/** Create a mock globalState Memento compatible with vscode.Memento interface. */
const createMockState = (): import("vscode").Memento => {
  const store = new Map<string, unknown>();
  return {
    get<T>(key: string, defaultValue?: T): T | undefined {
      return store.has(key) ? (store.get(key) as T) : defaultValue;
    },
    update: async (key: string, value: unknown): Promise<void> => {
      store.set(key, value);
    },
    keys: () => [...store.keys()],
  } as import("vscode").Memento;
};

describe("plan history", () => {
  it("returns empty array when no history", () => {
    const state = createMockState();
    expect(getHistory(state)).toEqual([]);
  });

  it("adds a history entry", async () => {
    const state = createMockState();
    await addHistoryEntry(state, { planType: "refactor", timestamp: 1000, title: "run 1" });
    const history = getHistory(state);
    expect(history).toHaveLength(1);
    expect(history[0]).toEqual({ planType: "refactor", timestamp: 1000, title: "run 1" });
  });

  it("prepends new entries (newest first)", async () => {
    const state = createMockState();
    await addHistoryEntry(state, { planType: "refactor", timestamp: 1000, title: "run 1" });
    await addHistoryEntry(state, { planType: "refactor", timestamp: 2000, title: "run 2" });
    const history = getHistory(state);
    expect(history).toHaveLength(2);
    expect(history[0]!.title).toBe("run 2");
    expect(history[1]!.title).toBe("run 1");
  });

  it("filters by plan type", async () => {
    const state = createMockState();
    await addHistoryEntry(state, { planType: "refactor", timestamp: 1000, title: "refactor run" });
    await addHistoryEntry(state, { planType: "documentation", timestamp: 2000, title: "doc run" });

    expect(getHistoryForType(state, "refactor")).toHaveLength(1);
    expect(getHistoryForType(state, "documentation")).toHaveLength(1);
    expect(getHistoryForType(state, "reconcile")).toHaveLength(0);
  });

  it("enforces per-type cap of 20 entries", async () => {
    const state = createMockState();
    for (let i = 0; i < 25; i++) {
      await addHistoryEntry(state, { planType: "refactor", timestamp: i, title: `run ${i}` });
    }
    const refactorHistory = getHistoryForType(state, "refactor");
    expect(refactorHistory).toHaveLength(20);
    // Newest should be first
    expect(refactorHistory[0]!.title).toBe("run 24");
  });

  it("cap applies per type independently", async () => {
    const state = createMockState();
    for (let i = 0; i < 25; i++) {
      await addHistoryEntry(state, { planType: "refactor", timestamp: i, title: `refactor ${i}` });
    }
    await addHistoryEntry(state, { planType: "documentation", timestamp: 100, title: "doc run" });

    expect(getHistoryForType(state, "refactor")).toHaveLength(20);
    expect(getHistoryForType(state, "documentation")).toHaveLength(1);
  });

  it("clears all history", async () => {
    const state = createMockState();
    await addHistoryEntry(state, { planType: "refactor", timestamp: 1000, title: "run 1" });
    await addHistoryEntry(state, { planType: "documentation", timestamp: 2000, title: "run 2" });
    await clearHistory(state);
    expect(getHistory(state)).toEqual([]);
  });

  it("clears history for a specific type only", async () => {
    const state = createMockState();
    await addHistoryEntry(state, { planType: "refactor", timestamp: 1000, title: "refactor run" });
    await addHistoryEntry(state, { planType: "documentation", timestamp: 2000, title: "doc run" });
    await clearHistoryForType(state, "refactor");

    expect(getHistoryForType(state, "refactor")).toHaveLength(0);
    expect(getHistoryForType(state, "documentation")).toHaveLength(1);
  });
});
