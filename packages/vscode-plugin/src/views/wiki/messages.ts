/**
 * @file Message types for the wiki sidebar WebviewView.
 *
 * The wiki viewer is a self-contained sidebar panel with:
 * - Navigation tree (page hierarchy)
 * - Search bar
 * - Content viewer
 *
 * All wiki data flows through the extension host, which calls the API.
 */

import type { WikiNav, WikiPage } from "@indexion/api-client";

/** Messages from extension host to wiki webview. */
export type WikiToWebview =
  | { readonly type: "navLoaded"; readonly nav: WikiNav }
  | { readonly type: "pageLoaded"; readonly page: WikiPage }
  | { readonly type: "searchResults"; readonly results: ReadonlyArray<WikiSearchHit> }
  | { readonly type: "loading"; readonly target: "nav" | "page" | "search" }
  | { readonly type: "error"; readonly message: string; readonly target: "nav" | "page" | "search" }
  | { readonly type: "serverStatus"; readonly ready: boolean };

/** Messages from wiki webview to extension host. */
export type WikiFromWebview =
  | { readonly type: "requestNav" }
  | { readonly type: "navigate"; readonly pageId: string }
  | { readonly type: "search"; readonly query: string }
  | { readonly type: "openFile"; readonly filePath: string; readonly line?: number };

/** A search hit returned from the wiki search API. */
export type WikiSearchHit = {
  readonly id: string;
  readonly title: string;
  readonly snippet?: string;
};
