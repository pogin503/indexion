/**
 * @file Resolve the codicons CSS URI for webview panels.
 *
 * The @vscode/codicons package provides the font and CSS.
 * vscode-icon from @vscode-elements/elements requires a
 * <link id="vscode-codicon-stylesheet"> element in the HTML.
 */

import * as vscode from "vscode";

/**
 * Resolve the webview-safe URI for codicons CSS.
 *
 * The CSS file references the font via a relative path,
 * so both must be accessible from the same localResourceRoots.
 */
export const resolveCodiconsUri = (webview: vscode.Webview, extensionUri: vscode.Uri): vscode.Uri => {
  const cssPath = vscode.Uri.joinPath(extensionUri, "node_modules", "@vscode", "codicons", "dist", "codicon.css");
  return webview.asWebviewUri(cssPath);
};
