/**
 * @file Tests for plans tree view items.
 */

import { TreeItemCollapsibleState } from "vscode";
import { PLAN_TYPES, buildRootItems, buildCategoryChildren, toTreeItem, type PlanTreeItem } from "./items.ts";

describe("PLAN_TYPES", () => {
  it("defines 6 plan types", () => {
    expect(PLAN_TYPES).toHaveLength(6);
  });

  it("each has unique id", () => {
    const ids = PLAN_TYPES.map((pt) => pt.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("each has a valid indexion command", () => {
    for (const pt of PLAN_TYPES) {
      expect(pt.command).toMatch(/^indexion\./);
    }
  });
});

describe("buildRootItems", () => {
  it("returns categories", () => {
    const roots = buildRootItems();
    expect(roots.length).toBeGreaterThanOrEqual(2);
    expect(roots.every((r) => r.type === "category")).toBe(true);
  });
});

describe("buildCategoryChildren", () => {
  it("returns plan types for a valid category", () => {
    const roots = buildRootItems();
    const first = roots[0];
    if (first?.type !== "category") {
      throw new Error("Expected category");
    }
    const children = buildCategoryChildren(first.categoryId);
    expect(children.length).toBeGreaterThan(0);
    expect(children.every((c) => c.type === "planType")).toBe(true);
  });

  it("returns empty for unknown category", () => {
    expect(buildCategoryChildren("nonexistent")).toEqual([]);
  });
});

describe("toTreeItem", () => {
  it("creates expanded tree item for category", () => {
    const item: PlanTreeItem = { type: "category", categoryId: "code", label: "Code Quality", icon: "beaker" };
    const treeItem = toTreeItem(item);
    expect(treeItem.label).toBe("Code Quality");
    expect(treeItem.collapsibleState).toBe(TreeItemCollapsibleState.Expanded);
  });

  it("creates collapsed tree item for plan type", () => {
    const children = buildCategoryChildren("code");
    const treeItem = toTreeItem(children[0]!);
    expect(treeItem.collapsibleState).toBe(TreeItemCollapsibleState.Collapsed);
    expect(treeItem.contextValue).toBe("planType");
  });

  it("creates leaf tree item for history entry", () => {
    const entry: PlanTreeItem = {
      type: "historyEntry",
      parentPlanTypeId: "refactor",
      entry: {
        planType: "refactor",
        timestamp: new Date("2026-04-05T10:30:00").getTime(),
        title: "src/ refactoring",
      },
    };
    const treeItem = toTreeItem(entry);
    expect(treeItem.collapsibleState).toBe(TreeItemCollapsibleState.None);
    expect(treeItem.description).toBe("src/ refactoring");
    expect(treeItem.contextValue).toBe("historyEntry");
  });
});
