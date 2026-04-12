/**
 * @file WebviewViewProvider for the explore sidebar panel.
 *
 * Replaces the old TreeView with a richer UI that includes
 * threshold slider, strategy selector, and directory picker.
 *
 * Uses the WebviewBridge handshake to avoid losing messages before
 * the React app has mounted.
 */

import * as vscode from "vscode";
import { runExplore, type HttpClient } from "@indexion/api-client";
import { resolveConfig } from "../../config/index.ts";
import type { ExploreFromWebview, ExploreToWebview } from "./messages.ts";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";
import { createWebviewBridge } from "../../extension-host/webview-bridge.ts";

/** Create the explore WebviewViewProvider. */
export const createExploreViewProvider = (
  extensionUri: vscode.Uri,
  getClient: () => HttpClient | undefined,
): vscode.WebviewViewProvider & { readonly notifyServerStatus: (ready: boolean) => void } => {
  const bridge = createWebviewBridge<ExploreToWebview>();

  const handleRun = async (threshold: number, strategy: string, targetDir: string): Promise<void> => {
    const client = getClient();
    if (!client) {
      bridge.post({ type: "error", message: "Server not ready" });
      return;
    }

    bridge.post({ type: "searching" });

    try {
      const result = await runExplore(client, {
        targetDirs: [targetDir],
        threshold,
        strategy,
      });

      if (!result.ok) {
        bridge.post({ type: "error", message: result.error });
        return;
      }

      bridge.post({ type: "results", pairs: result.data.pairs, fileCount: result.data.files.length });
    } catch (err) {
      bridge.post({ type: "error", message: err instanceof Error ? err.message : String(err) });
    }
  };

  return {
    notifyServerStatus: (ready: boolean) => {
      bridge.post({ type: "serverStatus", ready });
    },

    resolveWebviewView: (view: vscode.WebviewView) => {
      view.webview.options = {
        enableScripts: true,
        localResourceRoots: [vscode.Uri.joinPath(extensionUri, "dist", "webview")],
      };

      const scriptUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "explore.js"));
      const styleUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "style.css"));

      view.webview.html = buildWebviewHtml({
        webview: view.webview,
        scriptUri,
        styleUri,
        title: "Explore",
        allowInlineStyles: true,
      });

      bridge.attach(view, () => {
        // Send initial config and server status after React app is ready
        const config = resolveConfig();
        if (config) {
          bridge.post({
            type: "config",
            threshold: config.threshold,
            strategy: config.strategy,
          });
        }
        bridge.post({ type: "serverStatus", ready: getClient() !== undefined });
      });

      view.webview.onDidReceiveMessage((msg: ExploreFromWebview) => {
        if (msg.type === "run") {
          handleRun(msg.threshold, msg.strategy, msg.targetDir);
        }
        if (msg.type === "openDiff") {
          vscode.commands.executeCommand(
            "vscode.diff",
            vscode.Uri.file(msg.file1),
            vscode.Uri.file(msg.file2),
            `${msg.file1} ↔ ${msg.file2}`,
          );
        }
        if (msg.type === "pickDirectory") {
          const config = resolveConfig();
          const defaultUri = config ? vscode.Uri.file(config.workspaceDir) : undefined;
          vscode.window
            .showOpenDialog({
              canSelectFolders: true,
              canSelectFiles: false,
              canSelectMany: false,
              defaultUri,
              openLabel: "Select directory",
            })
            .then((folders) => {
              if (folders && folders.length > 0) {
                bridge.post({ type: "directoryPicked", path: folders[0].fsPath });
              }
            });
        }
      });
    },
  };
};
