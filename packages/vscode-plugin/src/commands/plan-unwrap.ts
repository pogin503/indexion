/**
 * @file Command handler for `indexion.planUnwrap`.
 */

import { runPlanUnwrap } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan unwrap command (report mode — dry-run/fix require CLI). */
export const executePlanUnwrap = async (): Promise<void> =>
  runPlanCommand("Unwrap Report", "indexion: Detecting wrapper functions...", (client, config, signal) =>
    runPlanUnwrap(
      client,
      {
        targetDir: config.workspaceDir,
        format: "md",
      },
      signal,
    ),
  );
