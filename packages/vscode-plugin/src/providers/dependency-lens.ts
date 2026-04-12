/**
 * @file KGF-based CodeLensProvider for dependency analysis.
 */

import * as vscode from "vscode";
import { extractEdges, type HttpClient } from "@indexion/api-client";

/** Create a KGF-based CodeLensProvider for dependencies. */
export const createDependencyLensProvider = (getClient: () => HttpClient | undefined): vscode.CodeLensProvider => ({
  provideCodeLenses: async (
    document: vscode.TextDocument,
    token: vscode.CancellationToken,
  ): Promise<Array<vscode.CodeLens>> => {
    const client = getClient();
    if (!client) {
      return [];
    }

    const abortController = new AbortController();
    token.onCancellationRequested(() => abortController.abort());

    const result = await extractEdges(client, { file: document.uri.fsPath }, abortController.signal);
    if (!result.ok) {
      return [];
    }

    const importEdges = result.data.filter((e) => e.kind === "Imports" || e.kind === "ModuleDependsOn");
    if (importEdges.length === 0) {
      return [];
    }

    const topRange = new vscode.Range(0, 0, 0, 0);
    const deps = importEdges.map((e) => e.to);
    const uniqueDeps = [...new Set(deps)];

    return [
      new vscode.CodeLens(topRange, {
        title: `${uniqueDeps.length} dependencies`,
        command: "indexion.docGraph",
        tooltip: `Dependencies: ${uniqueDeps.join(", ")}`,
      }),
    ];
  },
});
