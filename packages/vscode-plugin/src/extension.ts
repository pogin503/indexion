/**
 * @file Main entry point for the indexion VSCode extension.
 */

import * as vscode from "vscode";
import { registerCommands } from "./commands/index.ts";
import { registerProviders } from "./providers/index.ts";
import { resolveConfig } from "./config/index.ts";
import { createKgfListProvider } from "./views/kgf-list/provider.ts";
import { createSearchViewProvider } from "./views/search/provider.ts";
import { createExploreViewProvider } from "./views/explore/provider.ts";
import { createPlansProvider } from "./views/plans/provider.ts";
import { createWikiTreeProvider } from "./views/wiki/provider.ts";
import { createWikiPagePanelManager } from "./panels/wiki-page/panel.ts";
import { openSettingsPanel } from "./panels/settings/panel.ts";
import { createServerManager, type ServerManager } from "./server/server.ts";
import { setClientGetter } from "./server/client-accessor.ts";
import { addHistoryEntry, clearHistory } from "./views/plans/history.ts";

/** Module-level state holder for the server manager lifecycle. */
const state: { server: ServerManager | undefined } = { server: undefined };

/** Get the current HTTP client, or undefined if server not ready. */
const getClient = () => state.server?.getClient();

/** Public API exported to other extensions and E2E tests. */
export type ExtensionApi = {
  readonly isServerReady: () => boolean;
  readonly getClient: () => ReturnType<typeof getClient>;
  readonly getKgfSpecCount: () => number;
};

/** Extension activation. */
export const activate = (context: vscode.ExtensionContext): ExtensionApi => {
  const log = vscode.window.createOutputChannel("indexion");
  context.subscriptions.push(log);

  const folders = vscode.workspace.workspaceFolders;
  log.appendLine(`[activate] workspaceFolders: ${folders ? folders.map((f) => f.uri.fsPath).join(", ") : "none"}`);
  const config = resolveConfig();
  if (config) {
    log.appendLine(`[activate] workspace: ${config.workspaceDir}, specs: ${config.specsDir}`);
    state.server = createServerManager(
      {
        binaryPath: config.binaryPath,
        workspaceDir: config.workspaceDir,
        specsDir: config.specsDir,
        port: 0,
      },
      log,
    );
    state.server.start().catch((err) => {
      log.appendLine(`[activate] server start failed: ${err instanceof Error ? err.message : String(err)}`);
    });
    context.subscriptions.push({ dispose: () => state.server?.stop() });
  }

  setClientGetter(getClient);
  registerCommands(context);
  registerProviders(context, getClient);

  // --- Search WebviewView ---
  const searchProvider = createSearchViewProvider(context.extensionUri, getClient);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider("indexion.search", searchProvider, {
      webviewOptions: { retainContextWhenHidden: true },
    }),
  );

  // --- Explore WebviewView ---
  const exploreProvider = createExploreViewProvider(context.extensionUri, getClient);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider("indexion.explore", exploreProvider, {
      webviewOptions: { retainContextWhenHidden: true },
    }),
  );

  // --- Plans TreeView ---
  const plansProvider = createPlansProvider(context.globalState);
  vscode.window.registerTreeDataProvider("indexion.plans", plansProvider);

  // --- KGF Specs TreeView ---
  const kgfListProvider = createKgfListProvider(getClient, log);
  vscode.window.registerTreeDataProvider("indexion.kgfList", kgfListProvider);

  // --- Wiki TreeView (same pattern as KGF) ---
  const wikiTreeProvider = createWikiTreeProvider(getClient, log);
  vscode.window.registerTreeDataProvider("indexion.wiki", wikiTreeProvider);

  // --- Wiki page panel (editor area) ---
  const wikiPanelManager = createWikiPagePanelManager(context, getClient, log);

  // --- Server ready hook ---
  if (state.server) {
    const onReady = () => {
      log.appendLine("[activate] server became ready, refreshing views");
      kgfListProvider.refresh();
      wikiTreeProvider.refresh();
      searchProvider.notifyServerStatus(true);
      exploreProvider.notifyServerStatus(true);
    };

    if (state.server.isReady()) {
      onReady();
    } else {
      const disposable = state.server.onReady(() => {
        onReady();
        disposable.dispose();
      });
      context.subscriptions.push(disposable);
    }
  }

  // --- Commands ---
  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.kgfList", () => {
      kgfListProvider.refresh();
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.wikiOpen", () => {
      vscode.commands.executeCommand("indexion.wiki.focus");
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.wikiOpenPage", (pageId: string) => {
      wikiPanelManager.openPage(pageId);
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.wikiRefresh", () => {
      wikiTreeProvider.refresh();
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand(
      "indexion.planRun",
      async (item?: { readonly command?: string; readonly label?: string; readonly planTypeId?: string }) => {
        if (!item?.command) {
          return;
        }
        await vscode.commands.executeCommand(item.command);
        await addHistoryEntry(context.globalState, {
          planType: item.planTypeId ?? "unknown",
          timestamp: Date.now(),
          title: item.label ?? item.command,
        });
        plansProvider.refresh();
      },
    ),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.planClearHistory", async () => {
      await clearHistory(context.globalState);
      plansProvider.refresh();
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("indexion.openSettings", () => {
      openSettingsPanel(context);
    }),
  );

  return {
    isServerReady: () => state.server?.isReady() ?? false,
    getClient,
    getKgfSpecCount: () => kgfListProvider.getCachedSpecCount(),
  };
};

/** Extension deactivation. */
export const deactivate = (): void => {
  state.server?.stop();
  state.server = undefined;
};
