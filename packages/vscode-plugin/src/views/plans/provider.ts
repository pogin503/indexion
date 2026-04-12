/**
 * @file TreeDataProvider for the plans sidebar view.
 *
 * Shows plan types as top-level items with execution history as children.
 * Each plan type has an inline run button via contextValue + menus.
 */

import * as vscode from "vscode";
import type { PlanTreeItem } from "./items.ts";
import { PLAN_TYPES, planTypeItem, toTreeItem } from "./items.ts";
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
        return [...PLAN_TYPES.map(planTypeItem)];
      }

      if (element.type === "planType") {
        const history = getHistoryForType(globalState, element.planTypeId);
        return [...history.map((entry) => ({ type: "historyEntry" as const, entry }))];
      }

      return [];
    },
  };
};
