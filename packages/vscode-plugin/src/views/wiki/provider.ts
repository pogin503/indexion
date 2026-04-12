/**
 * @file WebviewViewProvider for the Wiki sidebar navigation.
 *
 * Shows a nav tree + search input. Page clicks open content
 * in an editor-area WebviewPanel via the onNavigate callback.
 *
 * Uses the WebviewBridge handshake to avoid losing messages before
 * the React app has mounted.
 */

import * as vscode from "vscode";
import { fetchWikiNav, searchWiki, type HttpClient } from "@indexion/api-client";
import type { WikiToWebview, WikiFromWebview } from "./messages.ts";
import { toWikiSearchHits } from "./messages.ts";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";
import { createWebviewBridge } from "../../extension-host/webview-bridge.ts";

/** Callback invoked when the user selects a page in the sidebar. */
export type WikiNavigateHandler = (pageId: string) => void;

/** Options for creating the wiki sidebar provider. */
type WikiViewProviderOptions = {
  readonly extensionUri: vscode.Uri;
  readonly getClient: () => HttpClient | undefined;
  readonly onNavigate: WikiNavigateHandler;
  readonly log?: { readonly appendLine: (msg: string) => void };
};

/** Create the wiki sidebar WebviewViewProvider. */
export const createWikiViewProvider = (
  options: WikiViewProviderOptions,
): vscode.WebviewViewProvider & { readonly notifyServerStatus: (ready: boolean) => void } => {
  const { extensionUri, getClient, onNavigate, log } = options;
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
    const hits = toWikiSearchHits(result.data as ReadonlyArray<Record<string, unknown>>);
    bridge.post({ type: "searchResults", results: hits });
  };

  return {
    notifyServerStatus: (ready: boolean) => {
      log?.appendLine(
        `[wiki] notifyServerStatus: ready=${ready}, bridgeReady=${bridge.isReady()}, bridgeAttached=${bridge.isAttached()}`,
      );
      bridge.post({ type: "serverStatus", ready });
      if (ready && bridge.isReady()) {
        loadNav();
      }
    },

    resolveWebviewView: (view: vscode.WebviewView) => {
      log?.appendLine("[wiki] resolveWebviewView called");
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
        const hasClient = getClient() !== undefined;
        log?.appendLine(`[wiki] bridge onReady: hasClient=${hasClient}`);
        bridge.post({ type: "serverStatus", ready: hasClient });
        if (hasClient) {
          loadNav();
        }
      });

      view.webview.onDidReceiveMessage((msg: WikiFromWebview) => {
        if (msg.type === "requestNav") {
          loadNav();
        }
        if (msg.type === "navigate") {
          onNavigate(msg.pageId);
        }
        if (msg.type === "search") {
          handleSearch(msg.query);
        }
      });
    },
  };
};
