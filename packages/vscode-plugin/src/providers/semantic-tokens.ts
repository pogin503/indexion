/**
 * @file KGF-based SemanticTokensProvider for syntax highlighting.
 */

import * as vscode from "vscode";
import { tokenizeFile, type HttpClient } from "@indexion/api-client";

/** Semantic token types supported by the provider. */
const TOKEN_TYPES = [
  "keyword",
  "variable",
  "type",
  "string",
  "number",
  "comment",
  "operator",
  "function",
  "namespace",
  "parameter",
  "property",
  "enumMember",
];

/** Semantic token modifiers. */
const TOKEN_MODIFIERS = ["declaration", "documentation", "readonly"];

/** The legend describing supported token types and modifiers. */
export const SEMANTIC_TOKEN_LEGEND = new vscode.SemanticTokensLegend(TOKEN_TYPES, TOKEN_MODIFIERS);

/** Map KGF token kind to semantic token type index. */
const mapTokenKind = (kind: string): { readonly typeIndex: number; readonly modifiers: number } | undefined => {
  if (kind.startsWith("KW_")) {
    return { typeIndex: 0, modifiers: 0 };
  }

  const mapping: Record<string, { readonly typeIndex: number; readonly modifiers: number }> = {
    Ident: { typeIndex: 1, modifiers: 0 },
    UpperIdent: { typeIndex: 2, modifiers: 0 },
    TypeIdent: { typeIndex: 2, modifiers: 0 },
    String: { typeIndex: 3, modifiers: 0 },
    TemplateString: { typeIndex: 3, modifiers: 0 },
    Number: { typeIndex: 4, modifiers: 0 },
    LineComment: { typeIndex: 5, modifiers: 0 },
    BlockComment: { typeIndex: 5, modifiers: 0 },
    DocComment: { typeIndex: 5, modifiers: 2 },
    DocLine: { typeIndex: 5, modifiers: 2 },
    Operator: { typeIndex: 6, modifiers: 0 },
  };

  return mapping[kind];
};

/** Create a KGF-based SemanticTokensProvider. */
export const createSemanticTokensProvider = (
  getClient: () => HttpClient | undefined,
): vscode.DocumentSemanticTokensProvider => ({
  provideDocumentSemanticTokens: async (
    document: vscode.TextDocument,
    token: vscode.CancellationToken,
  ): Promise<vscode.SemanticTokens | undefined> => {
    const client = getClient();
    if (!client) {
      return undefined;
    }

    const abortController = new AbortController();
    token.onCancellationRequested(() => abortController.abort());

    const result = await tokenizeFile(client, { file: document.uri.fsPath }, abortController.signal);
    if (!result.ok) {
      return undefined;
    }

    const builder = new vscode.SemanticTokensBuilder(SEMANTIC_TOKEN_LEGEND);

    for (const kgfToken of result.data) {
      const mapped = mapTokenKind(kgfToken.kind);
      if (!mapped) {
        continue;
      }

      const line = kgfToken.line - 1;
      const col = kgfToken.col - 1;
      if (line < 0 || col < 0) {
        continue;
      }

      builder.push(line, col, kgfToken.text.length, mapped.typeIndex, mapped.modifiers);
    }

    return builder.build();
  },
});
