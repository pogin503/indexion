/**
 * @file TreeItem types for the plans view.
 *
 * Organized by user task: what do you want to improve?
 * - Code quality: reduce duplication, remove indirection, extract common code
 * - Documentation: find gaps, detect drift, generate READMEs
 */

import * as vscode from "vscode";
import type { PlanHistoryEntry } from "./history.ts";

/** Plan type definition with user-facing metadata. */
type PlanTypeDef = {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
  readonly command: string;
  readonly description: string;
};

/** Plan category with child plan types. */
type PlanCategoryDef = {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
  readonly plans: ReadonlyArray<PlanTypeDef>;
};

const PLAN_CATEGORIES: ReadonlyArray<PlanCategoryDef> = [
  {
    id: "code",
    label: "Code Quality",
    icon: "beaker",
    plans: [
      {
        id: "refactor",
        label: "Find Duplication",
        icon: "tools",
        command: "indexion.planRefactor",
        description: "Detect duplicated code and suggest refactoring targets",
      },
      {
        id: "unwrap",
        label: "Remove Wrappers",
        icon: "fold",
        command: "indexion.planUnwrap",
        description: "Find unnecessary wrapper functions",
      },
      {
        id: "solid",
        label: "Extract Common",
        icon: "package",
        command: "indexion.planSolid",
        description: "Plan extraction of shared code into a common package",
      },
    ],
  },
  {
    id: "docs",
    label: "Documentation",
    icon: "book",
    plans: [
      {
        id: "documentation",
        label: "Coverage",
        icon: "checklist",
        command: "indexion.planDocumentation",
        description: "Analyze documentation gaps",
      },
      {
        id: "reconcile",
        label: "Detect Drift",
        icon: "git-compare",
        command: "indexion.planReconcile",
        description: "Find stale documentation that no longer matches code",
      },
      {
        id: "readme",
        label: "Generate README",
        icon: "markdown",
        command: "indexion.planReadme",
        description: "Generate package README files",
      },
    ],
  },
];

/** All plan types flattened (for backward compatibility). */
export const PLAN_TYPES = PLAN_CATEGORIES.flatMap((cat) => cat.plans);

/** Discriminated union for plan tree items. */
export type PlanTreeItem =
  | { readonly type: "category"; readonly categoryId: string; readonly label: string; readonly icon: string }
  | {
      readonly type: "planType";
      readonly planTypeId: string;
      readonly label: string;
      readonly icon: string;
      readonly command: string;
      readonly description: string;
    }
  | { readonly type: "historyEntry"; readonly entry: PlanHistoryEntry; readonly parentPlanTypeId: string };

/** Build the top-level items: categories. */
export const buildRootItems = (): ReadonlyArray<PlanTreeItem> =>
  PLAN_CATEGORIES.map((cat) => ({
    type: "category" as const,
    categoryId: cat.id,
    label: cat.label,
    icon: cat.icon,
  }));

/** Build children of a category: plan types. */
export const buildCategoryChildren = (categoryId: string): ReadonlyArray<PlanTreeItem> => {
  const cat = PLAN_CATEGORIES.find((c) => c.id === categoryId);
  if (!cat) {
    return [];
  }
  return cat.plans.map((pt) => ({
    type: "planType" as const,
    planTypeId: pt.id,
    label: pt.label,
    icon: pt.icon,
    command: pt.command,
    description: pt.description,
  }));
};

/** Convert a plan type to a PlanTreeItem (legacy compat). */
export const planTypeItem = (pt: PlanTypeDef): PlanTreeItem => ({
  type: "planType",
  planTypeId: pt.id,
  label: pt.label,
  icon: pt.icon,
  command: pt.command,
  description: pt.description,
});

/** Convert a PlanTreeItem to a VSCode TreeItem. */
export const toTreeItem = (item: PlanTreeItem): vscode.TreeItem => {
  if (item.type === "category") {
    const treeItem = new vscode.TreeItem(item.label, vscode.TreeItemCollapsibleState.Expanded);
    treeItem.iconPath = new vscode.ThemeIcon(item.icon);
    return treeItem;
  }

  if (item.type === "planType") {
    const treeItem = new vscode.TreeItem(item.label, vscode.TreeItemCollapsibleState.Collapsed);
    treeItem.iconPath = new vscode.ThemeIcon(item.icon);
    treeItem.description = item.description;
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
