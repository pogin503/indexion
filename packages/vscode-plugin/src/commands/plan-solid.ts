/**
 * @file Command handler for `indexion.planSolid`.
 */

import * as vscode from "vscode";
import { runPlanSolid } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan solid command. */
export const executePlanSolid = async (): Promise<void> => {
  const fromInput = await vscode.window.showInputBox({
    prompt: "Source directories to compare (comma-separated, at least 2)",
    placeHolder: "cmd/a/, cmd/b/",
  });
  if (!fromInput) {
    return;
  }
  const fromDirs = fromInput
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  if (fromDirs.length < 2) {
    vscode.window.showErrorMessage("At least 2 source directories required.");
    return;
  }
  const toDir = await vscode.window.showInputBox({
    prompt: "Target directory for extracted common code (optional)",
    placeHolder: "src/common/",
  });

  return runPlanCommand("Solid Extraction Plan", "indexion: Generating extraction plan...", (client, config, signal) =>
    runPlanSolid(
      client,
      {
        targetDir: config.workspaceDir,
        threshold: config.threshold,
        strategy: config.strategy,
        format: "md",
        fromDirs,
        toDir: toDir ?? undefined,
      },
      signal,
    ),
  );
};
