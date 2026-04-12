/**
 * @file Message types for the explore WebviewView communication.
 */

import type { SimilarityPair, ComparisonStrategy } from "@indexion/api-client";

/** Messages from extension host to explore webview. */
export type ExploreToWebview =
  | { readonly type: "results"; readonly pairs: ReadonlyArray<SimilarityPair>; readonly fileCount: number }
  | { readonly type: "searching" }
  | { readonly type: "error"; readonly message: string }
  | { readonly type: "directoryPicked"; readonly path: string }
  | { readonly type: "serverStatus"; readonly ready: boolean }
  | { readonly type: "config"; readonly threshold: number; readonly strategy: ComparisonStrategy };

/** Messages from explore webview to extension host. */
export type ExploreFromWebview =
  | { readonly type: "run"; readonly threshold: number; readonly strategy: string; readonly targetDir: string }
  | { readonly type: "openDiff"; readonly file1: string; readonly file2: string }
  | { readonly type: "pickDirectory" };
