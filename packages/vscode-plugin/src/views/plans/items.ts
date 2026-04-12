/**
 * @file TreeItem types for the plans view.
 */

import * as vscode from "vscode";
import type { PlanHistoryEntry } from "./history.ts";

/** The six available plan types with display metadata. */
export const PLAN_TYPES = [
  { id: "refactor", label: "Refactor", icon: "tools", command: "indexion.planRefactor" },
  { id: "documentation", label: "Documentation Coverage", icon: "book", command: "indexion.planDocumentation" },
  { id: "reconcile", label: "Reconcile", icon: "git-compare", command: "indexion.planReconcile" },
  { id: "solid", label: "Solid Extract", icon: "package", command: "indexion.planSolid" },
  { id: "unwrap", label: "Unwrap", icon: "fold", command: "indexion.planUnwrap" },
  { id: "readme", label: "Generate README", icon: "markdown", command: "indexion.planReadme" },
] as const;

/** Discriminated union for plan tree items. */
export type PlanTreeItem =
  | {
      readonly type: "planType";
      readonly planTypeId: string;
      readonly label: string;
      readonly icon: string;
      readonly command: string;
    }
  | { readonly type: "historyEntry"; readonly entry: PlanHistoryEntry };

/** Convert a plan type to a PlanTreeItem. */
export const planTypeItem = (pt: (typeof PLAN_TYPES)[number]): PlanTreeItem => ({
  type: "planType",
  planTypeId: pt.id,
  label: pt.label,
  icon: pt.icon,
  command: pt.command,
});

/** Convert a PlanTreeItem to a VSCode TreeItem. */
export const toTreeItem = (item: PlanTreeItem): vscode.TreeItem => {
  if (item.type === "planType") {
    const treeItem = new vscode.TreeItem(item.label, vscode.TreeItemCollapsibleState.Collapsed);
    treeItem.iconPath = new vscode.ThemeIcon(item.icon);
    treeItem.contextValue = "planType";
    return treeItem;
  }

  const date = new Date(item.entry.timestamp);
  const timeStr = date.toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
  const treeItem = new vscode.TreeItem(timeStr, vscode.TreeItemCollapsibleState.None);
  treeItem.description = item.entry.title;
  treeItem.iconPath = new vscode.ThemeIcon("history");
  treeItem.contextValue = "historyEntry";
  return treeItem;
};
