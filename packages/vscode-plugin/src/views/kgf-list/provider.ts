/**
 * @file TreeDataProvider for KGF specs list.
 */

import * as vscode from "vscode";
import { fetchKgfList, type HttpClient, type KgfSpecInfo } from "@indexion/api-client";
import type { KgfTreeItem, KgfCategoryItem } from "./items.ts";
import { toTreeItem } from "./items.ts";

/** Group specs by category. */
const groupByCategory = (specs: ReadonlyArray<KgfSpecInfo>): ReadonlyArray<KgfCategoryItem> => {
  const groups = new Map<string, Array<KgfSpecInfo>>();
  for (const spec of specs) {
    const category = spec.category || "other";
    const existing = groups.get(category) ?? [];
    existing.push(spec);
    groups.set(category, existing);
  }
  return [...groups.entries()].map(([name, groupSpecs]) => ({
    type: "category" as const,
    name,
    specs: groupSpecs,
  }));
};

/** Create a KGF list TreeDataProvider. */
export const createKgfListProvider = (
  getClient: () => HttpClient | undefined,
  log?: { appendLine: (msg: string) => void },
): vscode.TreeDataProvider<KgfTreeItem> & {
  readonly refresh: () => void;
  readonly getCachedSpecCount: () => number;
} => {
  const emitter = new vscode.EventEmitter<KgfTreeItem | undefined>();
  const cachedSpecs: { value: ReadonlyArray<KgfSpecInfo> } = { value: [] };

  const loadSpecs = async (): Promise<ReadonlyArray<KgfSpecInfo>> => {
    const client = getClient();
    if (!client) {
      log?.appendLine("[kgf-list] loadSpecs: no client available");
      return [];
    }
    const result = await fetchKgfList(client);
    if (!result.ok) {
      log?.appendLine(`[kgf-list] loadSpecs failed: ${result.error}`);
      return [];
    }
    log?.appendLine(`[kgf-list] loadSpecs: ${result.data.length} specs loaded`);
    cachedSpecs.value = result.data;
    return result.data;
  };

  return {
    onDidChangeTreeData: emitter.event,
    refresh: () => {
      // Eagerly fetch specs so data is ready even if TreeView is not visible.
      // emitter.fire triggers VSCode to call getChildren when the view becomes visible.
      loadSpecs().then(() => emitter.fire(undefined));
    },
    getCachedSpecCount: () => cachedSpecs.value.length,
    getTreeItem: (element: KgfTreeItem): vscode.TreeItem => toTreeItem(element),
    getChildren: async (element?: KgfTreeItem): Promise<Array<KgfTreeItem>> => {
      if (!element) {
        const specs = await loadSpecs();
        return [...groupByCategory(specs)];
      }
      if (element.type === "category") {
        return [...element.specs.map((spec) => ({ type: "spec" as const, spec }))];
      }
      return [];
    },
  };
};
