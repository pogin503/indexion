/**
 * @file Command handlers for KGF inspection.
 *
 * Note: kgf add/update are mutating operations without serve endpoints.
 * Use the CLI directly for those operations.
 */

import * as vscode from "vscode";
import { tokenizeFile } from "@indexion/api-client";
import { runWithProgress } from "./progress.ts";
import { requireConfig } from "./plan-common.ts";

/** Execute KGF inspect on the active file (shows tokens). */
export const executeKgfInspect = async (): Promise<void> => {
  const resolved = requireConfig();
  if (!resolved) {
    return;
  }

  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage("No active file to inspect.");
    return;
  }

  const result = await runWithProgress("indexion: Inspecting file with KGF...", (token) => {
    const abortController = new AbortController();
    token.onCancellationRequested(() => abortController.abort());
    return tokenizeFile(resolved.client, { file: editor.document.uri.fsPath }, abortController.signal);
  });

  if (!result.ok) {
    vscode.window.showErrorMessage(`KGF inspect failed: ${result.error}`);
    return;
  }

  const output = result.data.map((t) => `${t.line}:${t.col}\t${t.kind}\t${t.text}`).join("\n");

  const doc = await vscode.workspace.openTextDocument({ content: output, language: "plaintext" });
  await vscode.window.showTextDocument(doc, { preview: true });
};

/** Placeholder: kgf add requires CLI (no serve endpoint). */
export const executeKgfAdd = async (): Promise<void> => {
  vscode.window.showInformationMessage("KGF add is not available via the server. Use the CLI: indexion kgf add <spec>");
};

/** Placeholder: kgf update requires CLI (no serve endpoint). */
export const executeKgfUpdate = async (): Promise<void> => {
  vscode.window.showInformationMessage("KGF update is not available via the server. Use the CLI: indexion kgf update");
};
