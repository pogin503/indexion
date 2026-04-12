/**
 * @file Command handler for `indexion.planDocumentation`.
 */

import * as vscode from "vscode";
import { runPlanDocumentation } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan documentation command. */
export const executePlanDocumentation = async (): Promise<void> => {
  const stylePick = await vscode.window.showQuickPick(
    [
      { label: "full", description: "Full documentation analysis" },
      { label: "coverage", description: "Coverage summary only" },
    ],
    { placeHolder: "Documentation analysis style" },
  );
  if (!stylePick) {
    return;
  }

  return runPlanCommand(
    "Documentation Coverage",
    "indexion: Analyzing documentation coverage...",
    (client, config, signal) =>
      runPlanDocumentation(
        client,
        {
          targetDir: config.workspaceDir,
          format: "md",
          style: stylePick.label as "coverage" | "full",
        },
        signal,
      ),
  );
};
