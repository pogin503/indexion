/**
 * @file Shared utilities for command handlers (SoT for command boilerplate).
 */

import * as vscode from "vscode";
import type { HttpClient, ApiResponse } from "@indexion/api-client";
import { runWithProgress } from "./progress.ts";
import { getClient } from "../server/client-accessor.ts";
import { resolveConfig } from "../config/index.ts";
import type { ResolvedConfig } from "../config/index.ts";

/** Resolve config with workspace guard. Returns undefined and shows error if no workspace. */
export const requireConfig = (): { config: ResolvedConfig; client: HttpClient } | undefined => {
  const config = resolveConfig();
  if (!config) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return undefined;
  }
  const client = getClient();
  if (!client) {
    vscode.window.showErrorMessage("indexion server is not ready yet.");
    return undefined;
  }
  return { config, client };
};

/** Run a bridge task with progress and show the result as markdown. */
export const runPlanCommand = async (
  title: string,
  progressMessage: string,
  task: (client: HttpClient, config: ResolvedConfig, signal: AbortSignal) => Promise<ApiResponse<string>>,
): Promise<void> => {
  const resolved = requireConfig();
  if (!resolved) {
    return;
  }

  const result = await runWithProgress(progressMessage, (token) => {
    const abortController = new AbortController();
    token.onCancellationRequested(() => abortController.abort());
    return task(resolved.client, resolved.config, abortController.signal);
  });

  showPlanResult(title, result);
};

/** Show plan result in a new editor tab as markdown. */
export const showPlanResult = async (title: string, result: ApiResponse<string>): Promise<void> => {
  if (!result.ok) {
    vscode.window.showErrorMessage(`${title} failed: ${result.error}`);
    return;
  }

  const doc = await vscode.workspace.openTextDocument({
    content: result.data,
    language: "markdown",
  });
  await vscode.window.showTextDocument(doc, { preview: true });
};
