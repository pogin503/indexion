/**
 * @file Command handler for `indexion.planReconcile`.
 */

import { runPlanReconcile } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan reconcile command. */
export const executePlanReconcile = async (): Promise<void> =>
  runPlanCommand(
    "Reconcile Report",
    "indexion: Detecting implementation/documentation drift...",
    (client, config, signal) =>
      runPlanReconcile(
        client,
        {
          targetDir: config.workspaceDir,
          format: "md",
          specsDir: config.specsDir,
        },
        signal,
      ),
  );
