/**
 * @file TreeDataProvider for the Wiki navigation tree.
 *
 * Same pattern as KGF list: native VSCode tree with command on click.
 * Page content opens in an editor-area WebviewPanel via wikiOpenPage command.
 */

import * as vscode from "vscode";
import { fetchWikiNav, type HttpClient } from "@indexion/api-client";
import type { WikiTreeItem } from "./items.ts";
import { fromNavItem, toTreeItem } from "./items.ts";

/** Create the wiki tree data provider. */
export const createWikiTreeProvider = (
  getClient: () => HttpClient | undefined,
  log?: { readonly appendLine: (msg: string) => void },
): vscode.TreeDataProvider<WikiTreeItem> & { readonly refresh: () => void } => {
  const emitter = new vscode.EventEmitter<WikiTreeItem | undefined>();
  const cache: { pages: ReadonlyArray<WikiTreeItem> } = { pages: [] };

  const loadNav = async (): Promise<ReadonlyArray<WikiTreeItem>> => {
    const client = getClient();
    if (!client) {
      log?.appendLine("[wiki] loadNav: no client");
      return [];
    }
    const result = await fetchWikiNav(client);
    if (!result.ok) {
      log?.appendLine(`[wiki] loadNav failed: ${result.error}`);
      return [];
    }
    log?.appendLine(`[wiki] loadNav: ${result.data.pages.length} pages`);
    cache.pages = result.data.pages.map(fromNavItem);
    return cache.pages;
  };

  return {
    onDidChangeTreeData: emitter.event,

    refresh: () => {
      loadNav().then(() => emitter.fire(undefined));
    },

    getTreeItem: (element: WikiTreeItem): vscode.TreeItem => toTreeItem(element),

    getChildren: async (element?: WikiTreeItem): Promise<Array<WikiTreeItem>> => {
      if (!element) {
        const pages = await loadNav();
        return [...pages];
      }
      return [...element.children.map(fromNavItem)];
    },
  };
};
