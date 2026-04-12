/**
 * @file Message types for search WebviewView communication.
 */

import type { DigestMatch } from "@indexion/api-client";

/** Messages from extension host to search webview. */
export type SearchToWebview =
  | { readonly type: "results"; readonly items: ReadonlyArray<SearchResultItem> }
  | { readonly type: "searching" }
  | { readonly type: "error"; readonly message: string }
  | { readonly type: "serverStatus"; readonly ready: boolean };

/** Messages from search webview to extension host. */
export type SearchFromWebview =
  | { readonly type: "search"; readonly query: string }
  | { readonly type: "openFile"; readonly filePath: string; readonly line?: number };

/** Unified search result item for display. */
export type SearchResultItem = {
  readonly label: string;
  readonly description: string;
  readonly detail?: string;
  readonly filePath?: string;
  readonly line?: number;
  readonly score?: number;
};

/** Convert a DigestMatch to a SearchResultItem. */
export const digestMatchToSearchResult = (match: DigestMatch): SearchResultItem => ({
  label: match.name,
  description: match.file,
  detail: match.summary,
  filePath: match.file,
  score: match.score,
});
