/**
 * @file Command handler for `indexion.docGraph`.
 */

import * as vscode from "vscode";
import { generateDocGraph } from "@indexion/api-client";
import { runWithProgress } from "./progress.ts";
import { requireConfig } from "./plan-common.ts";
import type { DocGraphFormat } from "@indexion/api-client";

/** Execute doc graph command. */
export const executeDocGraph = async (): Promise<void> => {
  const resolved = requireConfig();
  if (!resolved) {
    return;
  }

  const formatPick = await vscode.window.showQuickPick(["mermaid", "json", "dot", "d2", "text"], {
    placeHolder: "Select graph output format",
  });

  const result = await runWithProgress("indexion: Generating dependency graph...", (token) => {
    const abortController = new AbortController();
    token.onCancellationRequested(() => abortController.abort());
    return generateDocGraph(
      resolved.client,
      {
        inputPaths: [resolved.config.workspaceDir],
        format: (formatPick as DocGraphFormat) ?? "mermaid",
        title: "Module Dependencies",
      },
      abortController.signal,
    );
  });

  if (!result.ok) {
    vscode.window.showErrorMessage(`Doc graph failed: ${result.error}`);
    return;
  }

  const langMap: Record<string, string> = {
    mermaid: "markdown",
    json: "json",
    dot: "plaintext",
    d2: "plaintext",
    text: "plaintext",
  };

  const format = formatPick ?? "mermaid";
  const content = format === "mermaid" ? `\`\`\`mermaid\n${result.data}\n\`\`\`` : result.data;

  const doc = await vscode.workspace.openTextDocument({ content, language: langMap[format] ?? "plaintext" });
  await vscode.window.showTextDocument(doc, { preview: true });
};
