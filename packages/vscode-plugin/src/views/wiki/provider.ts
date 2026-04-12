/**
 * @file WebviewViewProvider for the Wiki sidebar panel.
 *
 * A self-contained wiki viewer in the sidebar that combines:
 * - Navigation tree (from fetchWikiNav)
 * - Search bar (searchWiki)
 * - Content viewer (fetchWikiPage)
 *
 * Registered under the "indexionWiki" activity bar container,
 * giving Wiki its own dedicated icon in the activity bar.
 *
 * Uses the WebviewBridge handshake to avoid losing messages before
 * the React app has mounted.
 */

import * as vscode from "vscode";
import { fetchWikiNav, fetchWikiPage, searchWiki, type HttpClient } from "@indexion/api-client";
import type { WikiToWebview, WikiFromWebview, WikiSearchHit } from "./messages.ts";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";
import { createWebviewBridge } from "../../extension-host/webview-bridge.ts";

/** Create the wiki WebviewViewProvider. */
export const createWikiViewProvider = (
  extensionUri: vscode.Uri,
  getClient: () => HttpClient | undefined,
  log?: { readonly appendLine: (msg: string) => void },
): vscode.WebviewViewProvider & { readonly notifyServerStatus: (ready: boolean) => void } => {
  const bridge = createWebviewBridge<WikiToWebview>();

  const loadNav = async (): Promise<void> => {
    const client = getClient();
    if (!client) {
      log?.appendLine("[wiki] loadNav: no client");
      bridge.post({ type: "error", message: "Server not ready", target: "nav" });
      return;
    }
    log?.appendLine("[wiki] loadNav: fetching...");
    bridge.post({ type: "loading", target: "nav" });
    const result = await fetchWikiNav(client);
    if (!result.ok) {
      log?.appendLine(`[wiki] loadNav failed: ${result.error}`);
      bridge.post({ type: "error", message: result.error, target: "nav" });
      return;
    }
    log?.appendLine(`[wiki] loadNav: ${result.data.pages.length} pages`);
    bridge.post({ type: "navLoaded", nav: result.data });
  };

  const loadPage = async (pageId: string): Promise<void> => {
    const client = getClient();
    if (!client) {
      bridge.post({ type: "error", message: "Server not ready", target: "page" });
      return;
    }
    bridge.post({ type: "loading", target: "page" });
    const result = await fetchWikiPage(client, pageId);
    if (!result.ok) {
      bridge.post({ type: "error", message: result.error, target: "page" });
      return;
    }
    bridge.post({ type: "pageLoaded", page: result.data });
  };

  const handleSearch = async (query: string): Promise<void> => {
    const client = getClient();
    if (!client) {
      bridge.post({ type: "error", message: "Server not ready", target: "search" });
      return;
    }
    bridge.post({ type: "loading", target: "search" });
    const result = await searchWiki(client, { query, topK: 20 });
    if (!result.ok) {
      bridge.post({ type: "error", message: result.error, target: "search" });
      return;
    }
    const hits: ReadonlyArray<WikiSearchHit> = (result.data as ReadonlyArray<Record<string, unknown>>).map((hit) => ({
      id: String(hit["id"] ?? ""),
      title: String(hit["title"] ?? hit["id"] ?? ""),
      snippet: hit["snippet"] ? String(hit["snippet"]) : undefined,
    }));
    bridge.post({ type: "searchResults", results: hits });
  };

  return {
    notifyServerStatus: (ready: boolean) => {
      bridge.post({ type: "serverStatus", ready });
      if (ready && bridge.isReady()) {
        loadNav();
      }
    },

    resolveWebviewView: (view: vscode.WebviewView) => {
      view.webview.options = {
        enableScripts: true,
        localResourceRoots: [vscode.Uri.joinPath(extensionUri, "dist", "webview")],
      };

      const scriptUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "wiki-page.js"));
      const styleUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "style.css"));

      view.webview.html = buildWebviewHtml({
        webview: view.webview,
        scriptUri,
        styleUri,
        title: "Wiki",
        allowInlineStyles: true,
      });

      bridge.attach(view, () => {
        // React app is mounted — send initial state and load nav
        bridge.post({ type: "serverStatus", ready: getClient() !== undefined });
        if (getClient()) {
          loadNav();
        }
      });

      view.webview.onDidReceiveMessage((msg: WikiFromWebview) => {
        if (msg.type === "requestNav") {
          loadNav();
        }
        if (msg.type === "navigate") {
          loadPage(msg.pageId);
        }
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
