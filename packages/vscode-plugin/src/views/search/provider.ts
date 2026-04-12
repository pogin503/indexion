/**
 * @file WebviewViewProvider for the search sidebar panel.
 *
 * Code-only semantic search via queryDigest.
 *
 * Uses the WebviewBridge handshake to avoid losing messages before
 * the React app has mounted.
 */

import * as vscode from "vscode";
import { queryDigest, type HttpClient } from "@indexion/api-client";
import type { SearchFromWebview, SearchToWebview } from "./messages.ts";
import { digestMatchToSearchResult } from "./messages.ts";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";
import { createWebviewBridge } from "../../extension-host/webview-bridge.ts";

/** Create the search WebviewViewProvider. */
export const createSearchViewProvider = (
  extensionUri: vscode.Uri,
  getClient: () => HttpClient | undefined,
): vscode.WebviewViewProvider & { readonly notifyServerStatus: (ready: boolean) => void } => {
  const bridge = createWebviewBridge<SearchToWebview>();

  const handleSearch = async (query: string): Promise<void> => {
    const client = getClient();
    if (!client) {
      bridge.post({ type: "error", message: "Server not ready" });
      return;
    }

    bridge.post({ type: "searching" });

    try {
      const result = await queryDigest(client, { purpose: query, topK: 20 });
      if (!result.ok) {
        bridge.post({ type: "error", message: result.error });
        return;
      }
      const items = result.data.map(digestMatchToSearchResult);
      bridge.post({ type: "results", items });
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

      const scriptUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "search.js"));
      const styleUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "style.css"));

      view.webview.html = buildWebviewHtml({
        webview: view.webview,
        scriptUri,
        styleUri,
        title: "Search",
        allowInlineStyles: true,
      });

      bridge.attach(view, () => {
        bridge.post({ type: "serverStatus", ready: getClient() !== undefined });
      });

      view.webview.onDidReceiveMessage((msg: SearchFromWebview) => {
        if (msg.type === "search") {
          handleSearch(msg.query);
        }
        if (msg.type === "openFile") {
          const uri = vscode.Uri.file(msg.filePath);
          vscode.workspace.openTextDocument(uri).then((doc) => {
            const options: vscode.TextDocumentShowOptions = {};
            if (msg.line !== undefined) {
              const pos = new vscode.Position(Math.max(0, msg.line - 1), 0);
              options.selection = new vscode.Range(pos, pos);
            }
            vscode.window.showTextDocument(doc, options);
          });
        }
      });
    },
  };
};
