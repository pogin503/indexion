/**
 * @file Command registration for the indexion extension.
 */

import * as vscode from "vscode";
import { executeExplore } from "./explore.ts";
import { executePlanRefactor } from "./plan-refactor.ts";
import { executePlanDocumentation } from "./plan-documentation.ts";
import { executePlanReconcile } from "./plan-reconcile.ts";
import { executePlanSolid } from "./plan-solid.ts";
import { executePlanUnwrap } from "./plan-unwrap.ts";
import { executePlanReadme } from "./plan-readme.ts";
import { executeKgfInspect, executeKgfAdd, executeKgfUpdate } from "./kgf-inspect.ts";
import { executeDocGraph } from "./doc-graph.ts";
import { executeDigestQuery } from "./digest-query.ts";
import {
  executeSpecAlignDiff,
  executeSpecAlignTrace,
  executeSpecAlignSuggest,
  executeSpecAlignStatus,
} from "./spec-align.ts";
import { executeSearch } from "./search.ts";
import { executeGrep } from "./grep.ts";

/** Command registry mapping command IDs to handlers. */
const COMMAND_MAP: ReadonlyArray<readonly [string, () => Promise<void>]> = [
  ["indexion.explore", executeExplore],
  ["indexion.planRefactor", executePlanRefactor],
  ["indexion.planDocumentation", executePlanDocumentation],
  ["indexion.planReconcile", executePlanReconcile],
  ["indexion.planSolid", executePlanSolid],
  ["indexion.planUnwrap", executePlanUnwrap],
  ["indexion.planReadme", executePlanReadme],
  ["indexion.docGraph", executeDocGraph],
  ["indexion.kgfInspect", executeKgfInspect],
  ["indexion.kgfAdd", executeKgfAdd],
  ["indexion.kgfUpdate", executeKgfUpdate],
  ["indexion.digestQuery", executeDigestQuery],
  ["indexion.specAlignDiff", executeSpecAlignDiff],
  ["indexion.specAlignTrace", executeSpecAlignTrace],
  ["indexion.specAlignSuggest", executeSpecAlignSuggest],
  ["indexion.specAlignStatus", executeSpecAlignStatus],
  ["indexion.search", executeSearch],
  ["indexion.grep", executeGrep],
];

/** Register all commands and return disposables. */
export const registerCommands = (context: vscode.ExtensionContext): void => {
  for (const [id, handler] of COMMAND_MAP) {
    context.subscriptions.push(vscode.commands.registerCommand(id, handler));
  }
};
