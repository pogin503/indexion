/**
 * @file Command handler for `indexion.planRefactor`.
 */

import { runPlanRefactor } from "@indexion/api-client";
import { runPlanCommand } from "./plan-common.ts";

/** Execute plan refactor command. */
export const executePlanRefactor = async (): Promise<void> =>
  runPlanCommand("Refactoring Plan", "indexion: Generating refactoring plan...", (client, config, signal) =>
    runPlanRefactor(
      client,
      {
        targetDir: config.workspaceDir,
        threshold: config.threshold,
        strategy: config.strategy,
        includes: [],
        excludes: [],
        format: "md",
        style: "structured",
      },
      signal,
    ),
  );
