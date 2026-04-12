/**
 * @file Tests for plans TreeDataProvider.
 */

import { describe, it, expect } from "vitest";
import { createPlansProvider } from "./provider.ts";
import { PLAN_TYPES } from "./items.ts";
import type { PlanTreeItem } from "./items.ts";

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

/** Synchronous getChildren returns Array directly, but TS types it as ProviderResult. */
const getChildren = (provider: ReturnType<typeof createPlansProvider>, element?: PlanTreeItem): Array<PlanTreeItem> =>
  provider.getChildren(element) as Array<PlanTreeItem>;

describe("createPlansProvider", () => {
  it("returns plan types at root level", () => {
    const provider = createPlansProvider(createMockState());
    const children = getChildren(provider);
    expect(children).toHaveLength(PLAN_TYPES.length);
    for (const child of children) {
      expect(child.type).toBe("planType");
    }
  });

  it("returns empty history for plan type with no runs", () => {
    const provider = createPlansProvider(createMockState());
    const root = getChildren(provider);
    const refactorType = root.find((item) => item.type === "planType" && item.planTypeId === "refactor");
    expect(refactorType).toBeDefined();
    const history = getChildren(provider, refactorType!);
    expect(history).toHaveLength(0);
  });

  it("returns history entries as children of plan type", () => {
    const state = createMockState();
    state.update("indexion.planHistory", [
      { planType: "refactor", timestamp: 1000, title: "run 1" },
      { planType: "refactor", timestamp: 2000, title: "run 2" },
      { planType: "documentation", timestamp: 3000, title: "doc run" },
    ]);

    const provider = createPlansProvider(state);
    const root = getChildren(provider);
    const refactorType = root.find((item) => item.type === "planType" && item.planTypeId === "refactor")!;
    const refactorHistory = getChildren(provider, refactorType);
    expect(refactorHistory).toHaveLength(2);
    expect(refactorHistory[0]!.type).toBe("historyEntry");

    const docType = root.find((item) => item.type === "planType" && item.planTypeId === "documentation")!;
    const docHistory = getChildren(provider, docType);
    expect(docHistory).toHaveLength(1);
  });

  it("returns empty for history entry children", () => {
    const provider = createPlansProvider(createMockState());
    const historyItem: PlanTreeItem = {
      type: "historyEntry",
      entry: { planType: "refactor", timestamp: 1000, title: "test" },
    };
    expect(getChildren(provider, historyItem)).toHaveLength(0);
  });
});
