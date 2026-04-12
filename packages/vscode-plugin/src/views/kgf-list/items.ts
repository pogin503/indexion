/**
 * @file TreeItem types for the KGF specs tree view.
 */

import * as vscode from "vscode";
import type { KgfSpecInfo } from "@indexion/api-client";

/** A category node grouping KGF specs. */
export type KgfCategoryItem = {
  readonly type: "category";
  readonly name: string;
  readonly specs: ReadonlyArray<KgfSpecInfo>;
};

/** A leaf node representing a single KGF spec. */
export type KgfSpecItem = {
  readonly type: "spec";
  readonly spec: KgfSpecInfo;
};

/** Union of all KGF tree items. */
export type KgfTreeItem = KgfCategoryItem | KgfSpecItem;

/** Create a VSCode TreeItem from a KGF tree item. */
export const toTreeItem = (item: KgfTreeItem): vscode.TreeItem => {
  if (item.type === "category") {
    const treeItem = new vscode.TreeItem(item.name, vscode.TreeItemCollapsibleState.Expanded);
    treeItem.iconPath = new vscode.ThemeIcon("folder");
    treeItem.description = `${item.specs.length} specs`;
    return treeItem;
  }

  const treeItem = new vscode.TreeItem(item.spec.name, vscode.TreeItemCollapsibleState.None);
  treeItem.description = item.spec.sources.join(", ");
  treeItem.iconPath = new vscode.ThemeIcon("file-code");
  treeItem.contextValue = "kgfSpec";
  treeItem.command = {
    command: "indexion.kgfInspect",
    title: "Inspect",
    arguments: [item.spec.name],
  };
  return treeItem;
};
