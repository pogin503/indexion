/**
 * @file Tests for plans TreeDataProvider.
 */

import { describe, it, expect } from "vitest";
import { createPlansProvider } from "./provider.ts";
import type { PlanTreeItem } from "./items.ts";

/** Create a mock globalState Memento. */
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

const getChildren = (provider: ReturnType<typeof createPlansProvider>, element?: PlanTreeItem): Array<PlanTreeItem> =>
  provider.getChildren(element) as Array<PlanTreeItem>;

describe("createPlansProvider", () => {
  it("returns categories at root level", () => {
    const provider = createPlansProvider(createMockState());
    const roots = getChildren(provider);
    expect(roots.length).toBeGreaterThanOrEqual(2);
    for (const root of roots) {
      expect(root.type).toBe("category");
    }
  });

  it("returns plan types as children of category", () => {
    const provider = createPlansProvider(createMockState());
    const roots = getChildren(provider);
    const codeCategory = roots.find((r) => r.type === "category" && r.categoryId === "code");
    expect(codeCategory).toBeDefined();
    const plans = getChildren(provider, codeCategory!);
    expect(plans.length).toBeGreaterThan(0);
    for (const plan of plans) {
      expect(plan.type).toBe("planType");
    }
  });

  it("returns empty history for plan type with no runs", () => {
    const provider = createPlansProvider(createMockState());
    const roots = getChildren(provider);
    const category = roots[0]!;
    const plans = getChildren(provider, category);
    const history = getChildren(provider, plans[0]!);
    expect(history).toHaveLength(0);
  });

  it("returns history entries as children of plan type", () => {
    const state = createMockState();
    state.update("indexion.planHistory", [
      { planType: "refactor", timestamp: 1000, title: "run 1" },
      { planType: "refactor", timestamp: 2000, title: "run 2" },
    ]);

    const provider = createPlansProvider(state);
    const roots = getChildren(provider);
    const codeCategory = roots.find((r) => r.type === "category" && r.categoryId === "code")!;
    const plans = getChildren(provider, codeCategory);
    const refactor = plans.find((p) => p.type === "planType" && p.planTypeId === "refactor")!;
    const history = getChildren(provider, refactor);
    expect(history).toHaveLength(2);
    expect(history[0]!.type).toBe("historyEntry");
  });

  it("returns empty for history entry children", () => {
    const provider = createPlansProvider(createMockState());
    const historyItem: PlanTreeItem = {
      type: "historyEntry",
      parentPlanTypeId: "refactor",
      entry: { planType: "refactor", timestamp: 1000, title: "test" },
    };
    expect(getChildren(provider, historyItem)).toHaveLength(0);
  });
});
