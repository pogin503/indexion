/**
 * @file Message types for the wiki sidebar WebviewView.
 *
 * The wiki sidebar shows navigation (tree + search).
 * Page content is opened in a separate editor-area WebviewPanel.
 */

import type { WikiNav } from "@indexion/api-client";

/** Messages from extension host to wiki sidebar webview. */
export type WikiToWebview =
  | { readonly type: "navLoaded"; readonly nav: WikiNav }
  | { readonly type: "searchResults"; readonly results: ReadonlyArray<WikiSearchHit> }
  | { readonly type: "loading"; readonly target: "nav" | "search" }
  | { readonly type: "error"; readonly message: string; readonly target: "nav" | "search" }
  | { readonly type: "serverStatus"; readonly ready: boolean };

/** Messages from wiki sidebar webview to extension host. */
export type WikiFromWebview =
  | { readonly type: "requestNav" }
  | { readonly type: "navigate"; readonly pageId: string }
  | { readonly type: "search"; readonly query: string };

/** A search hit returned from the wiki search API. */
export type WikiSearchHit = {
  readonly id: string;
  readonly title: string;
  readonly snippet?: string;
};

/** Convert raw API search results to typed WikiSearchHit array. */
export const toWikiSearchHits = (raw: ReadonlyArray<Record<string, unknown>>): ReadonlyArray<WikiSearchHit> =>
  raw.map((hit) => ({
    id: String(hit["id"] ?? ""),
    title: String(hit["title"] ?? hit["id"] ?? ""),
    snippet: hit["snippet"] ? String(hit["snippet"]) : undefined,
  }));
