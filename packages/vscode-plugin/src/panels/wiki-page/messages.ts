/**
 * @file Message types for the wiki page viewer WebviewPanel.
 */

import type { WikiPage } from "@indexion/api-client";

/** Messages from extension host to wiki page webview. */
export type WikiPageToWebview =
  | { readonly type: "pageLoaded"; readonly page: WikiPage }
  | { readonly type: "loading" }
  | { readonly type: "error"; readonly message: string };

/** Messages from wiki page webview to extension host. */
export type WikiPageFromWebview =
  | { readonly type: "openFile"; readonly filePath: string; readonly line?: number }
  | { readonly type: "navigate"; readonly pageId: string };
