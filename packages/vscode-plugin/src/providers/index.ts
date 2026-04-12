/**
 * @file Provider registration for the indexion extension.
 */

import * as vscode from "vscode";
import type { HttpClient } from "@indexion/api-client";
import { createOutlineProvider } from "./outline.ts";
import { createSemanticTokensProvider, SEMANTIC_TOKEN_LEGEND } from "./semantic-tokens.ts";
import { createDependencyLensProvider } from "./dependency-lens.ts";

/** Register all language providers and return disposables. */
export const registerProviders = (context: vscode.ExtensionContext, getClient: () => HttpClient | undefined): void => {
  const allLanguages: vscode.DocumentFilter = { scheme: "file" };

  context.subscriptions.push(
    vscode.languages.registerDocumentSymbolProvider(allLanguages, createOutlineProvider(getClient)),
  );

  context.subscriptions.push(
    vscode.languages.registerDocumentSemanticTokensProvider(
      allLanguages,
      createSemanticTokensProvider(getClient),
      SEMANTIC_TOKEN_LEGEND,
    ),
  );

  context.subscriptions.push(
    vscode.languages.registerCodeLensProvider(allLanguages, createDependencyLensProvider(getClient)),
  );
};
