/**
 * @file HTML generation for webview panels and views.
 *
 * Used by all WebviewPanel and WebviewViewProvider implementations
 * on the extension host side to produce the HTML shell that loads
 * the React app with proper CSP and nonce.
 */

import type * as vscode from "vscode";

/** Generate a cryptographically random nonce for Content Security Policy. */
export const generateNonce = (): string => {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const values = new Uint8Array(32);
  crypto.getRandomValues(values);
  return [...values].map((v) => chars[v % chars.length]).join("");
};

/** Options for generating webview HTML. */
export type WebviewHtmlOptions = {
  readonly webview: vscode.Webview;
  readonly scriptUri: vscode.Uri;
  readonly styleUri: vscode.Uri;
  readonly title: string;
  /** Allow inline styles via 'unsafe-inline' in CSP. Needed for React inline styles. */
  readonly allowInlineStyles?: boolean;
};

/** Build the CSP style-src directive based on options. */
const resolveStyleSrc = (options: WebviewHtmlOptions): string => {
  if (options.allowInlineStyles) {
    return `${options.webview.cspSource} 'unsafe-inline'`;
  }
  return `${options.webview.cspSource}`;
};

/** Generate HTML content for a webview with CSP, script, and stylesheet. */
export const buildWebviewHtml = (options: WebviewHtmlOptions): string => {
  const nonce = generateNonce();
  const styleSrc = resolveStyleSrc(options);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${styleSrc}; script-src 'nonce-${nonce}' ${options.webview.cspSource};">
  <link rel="stylesheet" href="${options.styleUri}">
  <title>${options.title}</title>
  <style nonce="${nonce}">body{margin:0;padding:0;overflow:hidden}html,body,#root{height:100%;width:100%}</style>
</head>
<body>
  <div id="root"></div>
  <script type="module" nonce="${nonce}" src="${options.scriptUri}"></script>
</body>
</html>`;
};
