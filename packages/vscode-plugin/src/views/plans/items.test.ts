/**
 * @file Tests for plans tree view items.
 */

import { TreeItemCollapsibleState } from "vscode";
import { PLAN_TYPES, planTypeItem, toTreeItem, type PlanTreeItem } from "./items.ts";

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

describe("toTreeItem", () => {
  it("creates collapsed tree item for plan type", () => {
    const item: PlanTreeItem = planTypeItem(PLAN_TYPES[0]);
    const treeItem = toTreeItem(item);
    expect(treeItem.label).toBe(PLAN_TYPES[0].label);
    expect(treeItem.collapsibleState).toBe(TreeItemCollapsibleState.Collapsed);
    expect(treeItem.contextValue).toBe("planType");
  });

  it("creates leaf tree item for history entry", () => {
    const entry: PlanTreeItem = {
      type: "historyEntry",
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
