/**
 * @file TreeDataProvider for the plans sidebar view.
 *
 * Three-level hierarchy:
 *   Category (Code Quality / Documentation)
 *     └─ Plan Type (Find Duplication, Coverage, ...)
 *         └─ History Entry (timestamp + title)
 */

import * as vscode from "vscode";
import type { PlanTreeItem } from "./items.ts";
import { buildRootItems, buildCategoryChildren, toTreeItem } from "./items.ts";
import { getHistoryForType } from "./history.ts";

/** Create the plans TreeDataProvider. */
export const createPlansProvider = (
  globalState: vscode.Memento,
): vscode.TreeDataProvider<PlanTreeItem> & { readonly refresh: () => void } => {
  const emitter = new vscode.EventEmitter<PlanTreeItem | undefined>();

  return {
    onDidChangeTreeData: emitter.event,

    refresh: () => {
      emitter.fire(undefined);
    },

    getTreeItem: (element: PlanTreeItem): vscode.TreeItem => toTreeItem(element),

    getChildren: (element?: PlanTreeItem): Array<PlanTreeItem> => {
      if (!element) {
        return [...buildRootItems()];
      }

      if (element.type === "category") {
        return [...buildCategoryChildren(element.categoryId)];
      }

      if (element.type === "planType") {
        const history = getHistoryForType(globalState, element.planTypeId);
        return [
          ...history.map((entry) => ({ type: "historyEntry" as const, entry, parentPlanTypeId: element.planTypeId })),
        ];
      }

      return [];
    },
  };
};
