/**
 * @file Message types for plan results webview communication.
 */

/** Messages from extension host to plan results webview. */
export type PlanResultsToWebview = {
  readonly type: "resultLoaded";
  readonly title: string;
  readonly content: string;
  readonly format: string;
};

/** Messages from plan results webview to extension host. */
export type PlanResultsFromWebview =
  | { readonly type: "openFile"; readonly filePath: string }
  | { readonly type: "copyContent" };
