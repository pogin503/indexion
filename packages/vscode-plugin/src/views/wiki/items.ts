/**
 * @file TreeItem types for the wiki navigation tree.
 *
 * Same pattern as KGF list: TreeDataProvider with command on leaf items.
 */

import * as vscode from "vscode";
import type { WikiNavItem } from "@indexion/api-client";

/** A wiki tree item — mirrors WikiNavItem structure. */
export type WikiTreeItem = {
  readonly id: string;
  readonly title: string;
  readonly children: ReadonlyArray<WikiNavItem>;
};

/** Convert a WikiNavItem to a WikiTreeItem. */
export const fromNavItem = (item: WikiNavItem): WikiTreeItem => ({
  id: item.id,
  title: item.title,
  children: item.children,
});

/** Convert a WikiTreeItem to a VSCode TreeItem. */
export const toTreeItem = (item: WikiTreeItem): vscode.TreeItem => {
  const hasChildren = item.children.length > 0;
  const treeItem = new vscode.TreeItem(
    item.title,
    hasChildren ? vscode.TreeItemCollapsibleState.Collapsed : vscode.TreeItemCollapsibleState.None,
  );
  treeItem.iconPath = new vscode.ThemeIcon(hasChildren ? "folder" : "file");
  treeItem.command = {
    command: "indexion.wikiOpenPage",
    title: "Open Page",
    arguments: [item.id],
  };
  return treeItem;
};
