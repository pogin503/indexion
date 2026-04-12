/**
 * @file Command handlers for KGF inspection.
 *
 * - From tree view (with specName): opens the .kgf spec file in the editor.
 * - From command palette (no specName): tokenizes the active editor file.
 */

import * as vscode from "vscode";
import { tokenizeFile } from "@indexion/api-client";
import { runWithProgress } from "./progress.ts";
import { requireConfig } from "./plan-common.ts";
import { resolveConfig } from "../config/index.ts";

/** Open a KGF spec file by name. Searches the specsDir recursively. */
const openSpecFile = async (specName: string): Promise<void> => {
  const config = resolveConfig();
  if (!config) {
    return;
  }

  const pattern = new vscode.RelativePattern(config.workspaceDir, `${config.specsDir}/**/${specName}.kgf`);
  const files = await vscode.workspace.findFiles(pattern, null, 1);

  if (files.length === 0) {
    vscode.window.showWarningMessage(`KGF spec file not found: ${specName}.kgf`);
    return;
  }

  const doc = await vscode.workspace.openTextDocument(files[0]!);
  await vscode.window.showTextDocument(doc, { preview: true });
};

/** Execute KGF inspect. */
export const executeKgfInspect = async (specName?: string): Promise<void> => {
  // From tree view: open the spec file itself
  if (specName) {
    await openSpecFile(specName);
    return;
  }

  // From command palette: tokenize the active file
  const resolved = requireConfig();
  if (!resolved) {
    return;
  }

  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage("No active file to inspect. Open a file first.");
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
