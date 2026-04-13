/**
 * @file Unified search WebviewViewProvider with SSE streaming.
 *
 * A single sidebar panel that supports 4 search modes:
 * - search:  full-text/semantic search via /search/stream
 * - explore: code similarity analysis via /explore/stream
 * - grep:    KGF token pattern search via /grep/stream
 * - digest:  function search by purpose via /digest/query/stream
 *
 * All modes use SSE streaming for incremental result delivery.
 * Results appear one-by-one as the server produces them,
 * with progress phase indicators during computation.
 */

import * as vscode from "vscode";
import { postStream, type SseEvent } from "@indexion/api-client";
import type { SearchFromWebview, SearchToWebview, SearchResultItem, ExplorePairItem } from "./messages.ts";
import { searchHitToItem, digestMatchToItem, grepMatchToItem, similarityPairToItem } from "./messages.ts";
import type { SearchHit, DigestMatch, GrepMatch, SimilarityPair, ExploreResult } from "@indexion/api-client";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";
import { createWebviewBridge } from "../../extension-host/webview-bridge.ts";
import { resolveCodiconsUri } from "../../extension-host/codicons.ts";
import { resolveConfig } from "../../config/index.ts";

/** Maps SSE item data to SearchResultItem based on search mode. */
const mapSseItem = (data: unknown, mode: "search" | "grep" | "digest"): SearchResultItem => {
  switch (mode) {
    case "search":
      return searchHitToItem(data as SearchHit);
    case "grep":
      return grepMatchToItem(data as GrepMatch);
    case "digest":
      return digestMatchToItem(data as DigestMatch);
  }
};

/** Create the unified search WebviewViewProvider. */
export const createSearchViewProvider = (
  extensionUri: vscode.Uri,
  getBaseUrl: () => string | undefined,
): vscode.WebviewViewProvider & { readonly notifyServerStatus: (ready: boolean) => void } => {
  const bridge = createWebviewBridge<SearchToWebview>();

  /** Shared streaming handler for search/grep/digest modes. */
  const handleStream = (path: string, body: unknown, mode: "search" | "grep" | "digest"): void => {
    const baseUrl = getBaseUrl();
    if (!baseUrl) {
      bridge.post({ type: "error", message: "Server not ready" });
      return;
    }

    bridge.post({ type: "searching" });

    postStream(baseUrl, path, {
      body,
      onEvent: (event: SseEvent) => {
        switch (event.type) {
          case "progress":
            bridge.post({ type: "progress", phase: event.phase, detail: event.detail });
            break;
          case "item":
            bridge.post({ type: "appendItems", items: [mapSseItem(event.data, mode)] });
            break;
          case "items":
            bridge.post({
              type: "appendItems",
              items: (event.data as ReadonlyArray<unknown>).map((d) => mapSseItem(d, mode)),
            });
            break;
          case "done":
            bridge.post({ type: "done", total: event.total });
            break;
          case "error":
            bridge.post({ type: "error", message: event.message });
            break;
        }
      },
    }).catch((err) => {
      bridge.post({ type: "error", message: err instanceof Error ? err.message : String(err) });
    });
  };

  /** Streaming handler for explore mode (different result shape). */
  const handleExploreStream = (threshold: number, strategy: string, targetDir: string): void => {
    const baseUrl = getBaseUrl();
    if (!baseUrl) {
      bridge.post({ type: "error", message: "Server not ready" });
      return;
    }

    bridge.post({ type: "searching" });

    postStream(baseUrl, "/explore/stream", {
      body: { targetDirs: [targetDir], threshold, strategy },
      onEvent: (event: SseEvent) => {
        switch (event.type) {
          case "progress":
            bridge.post({ type: "progress", phase: event.phase, detail: event.detail });
            break;
          case "result": {
            const exploreResult = event.data as ExploreResult;
            const pairs: ReadonlyArray<ExplorePairItem> = exploreResult.pairs.map((p: SimilarityPair) =>
              similarityPairToItem(p),
            );
            bridge.post({ type: "exploreResults", pairs, fileCount: exploreResult.files.length });
            break;
          }
          case "done":
            bridge.post({ type: "done", total: event.total });
            break;
          case "error":
            bridge.post({ type: "error", message: event.message });
            break;
        }
      },
    }).catch((err) => {
      bridge.post({ type: "error", message: err instanceof Error ? err.message : String(err) });
    });
  };

  return {
    notifyServerStatus: (ready: boolean) => {
      bridge.post({ type: "serverStatus", ready });
    },

    resolveWebviewView: (view: vscode.WebviewView) => {
      view.webview.options = {
        enableScripts: true,
        localResourceRoots: [
          vscode.Uri.joinPath(extensionUri, "dist", "webview"),
          vscode.Uri.joinPath(extensionUri, "node_modules", "@vscode", "codicons", "dist"),
        ],
      };

      const scriptUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "search.js"));
      const styleUri = view.webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, "dist", "webview", "style.css"));
      const codiconsUri = resolveCodiconsUri(view.webview, extensionUri);

      view.webview.html = buildWebviewHtml({
        webview: view.webview,
        scriptUri,
        styleUri,
        codiconsUri,
        title: "Search",
        allowInlineStyles: true,
      });

      bridge.attach(view, () => {
        const config = resolveConfig();
        if (config) {
          bridge.post({ type: "config", threshold: config.threshold, strategy: config.strategy });
        }
        bridge.post({ type: "serverStatus", ready: getBaseUrl() !== undefined });
      });

      view.webview.onDidReceiveMessage((msg: SearchFromWebview) => {
        switch (msg.type) {
          case "search":
            handleStream("/search/stream", { query: msg.query, topK: 30 }, "search");
            break;
          case "digest":
            handleStream("/digest/query/stream", { purpose: msg.query, topK: 20 }, "digest");
            break;
          case "grep":
            handleStream("/grep/stream", { pattern: msg.pattern }, "grep");
            break;
          case "explore":
            handleExploreStream(msg.threshold, msg.strategy, msg.targetDir);
            break;
          case "openFile": {
            const uri = vscode.Uri.file(msg.filePath);
            vscode.workspace.openTextDocument(uri).then((doc) => {
              const options: vscode.TextDocumentShowOptions = {};
              if (msg.line !== undefined) {
                const pos = new vscode.Position(Math.max(0, msg.line - 1), 0);
                options.selection = new vscode.Range(pos, pos);
              }
              vscode.window.showTextDocument(doc, options);
            });
            break;
          }
          case "openDiff":
            vscode.commands.executeCommand(
              "vscode.diff",
              vscode.Uri.file(msg.file1),
              vscode.Uri.file(msg.file2),
              `${msg.file1} ↔ ${msg.file2}`,
            );
            break;
          case "pickDirectory": {
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
            break;
          }
        }
      });
    },
  };
};
