/**
 * @file Command handler for `indexion.planReadme`.
 */

import * as vscode from "vscode";
import { runPlanReadme } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan readme command. */
export const executePlanReadme = async (): Promise<void> => {
  const templateUri = await vscode.window.showOpenDialog({
    canSelectFiles: true,
    canSelectFolders: false,
    canSelectMany: false,
    filters: { "Template files": ["md", "txt", "tpl"] },
    title: "Select README template with {{include:...}} placeholders",
  });
  if (!templateUri || templateUri.length === 0) {
    return;
  }
  const template = templateUri[0].fsPath;

  return runPlanCommand("README Generation Plan", "indexion: Generating README plan...", (client, config, signal) =>
    runPlanReadme(
      client,
      {
        targetDir: config.workspaceDir,
        format: "md",
        template,
      },
      signal,
    ),
  );
};
