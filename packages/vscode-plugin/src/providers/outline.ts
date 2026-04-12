/**
 * @file KGF-based DocumentSymbolProvider for code outline.
 */

import * as vscode from "vscode";
import { tokenizeFile, type HttpClient, type KgfToken } from "@indexion/api-client";

/** Token kinds that indicate a declaration boundary. */
const DECLARATION_KEYWORDS = new Set([
  "KW_fn",
  "KW_function",
  "KW_def",
  "KW_func",
  "KW_class",
  "KW_struct",
  "KW_enum",
  "KW_trait",
  "KW_type",
  "KW_interface",
  "KW_impl",
  "KW_const",
  "KW_let",
  "KW_var",
  "KW_val",
  "KW_pub",
  "KW_export",
]);

/** Token kinds that represent identifiers after a keyword. */
const IDENT_KINDS = new Set(["Ident", "TypeIdent", "UpperIdent"]);

/** Map declaration keyword to VSCode SymbolKind. */
const keywordToSymbolKind = (keyword: string): vscode.SymbolKind => {
  const mapping: Record<string, vscode.SymbolKind> = {
    KW_fn: vscode.SymbolKind.Function,
    KW_function: vscode.SymbolKind.Function,
    KW_def: vscode.SymbolKind.Function,
    KW_func: vscode.SymbolKind.Function,
    KW_class: vscode.SymbolKind.Class,
    KW_struct: vscode.SymbolKind.Struct,
    KW_enum: vscode.SymbolKind.Enum,
    KW_trait: vscode.SymbolKind.Interface,
    KW_type: vscode.SymbolKind.TypeParameter,
    KW_interface: vscode.SymbolKind.Interface,
    KW_impl: vscode.SymbolKind.Class,
    KW_const: vscode.SymbolKind.Constant,
    KW_let: vscode.SymbolKind.Variable,
    KW_var: vscode.SymbolKind.Variable,
    KW_val: vscode.SymbolKind.Variable,
  };
  return mapping[keyword] ?? vscode.SymbolKind.Variable;
};

/** Extract symbols from KGF tokens. */
const tokensToSymbols = (tokens: ReadonlyArray<KgfToken>): Array<vscode.DocumentSymbol> => {
  const symbols: Array<vscode.DocumentSymbol> = [];
  const tokenArr = [...tokens];

  for (const [i, token] of tokenArr.entries()) {
    if (token.kind === "KW_pub" || token.kind === "KW_export") {
      const next = tokenArr[i + 1];
      const nameToken = next && DECLARATION_KEYWORDS.has(next.kind) ? tokenArr[i + 2] : undefined;
      if (nameToken && IDENT_KINDS.has(nameToken.kind)) {
        const range = new vscode.Range(
          new vscode.Position(nameToken.line - 1, nameToken.col - 1),
          new vscode.Position(nameToken.line - 1, nameToken.col - 1 + nameToken.text.length),
        );
        symbols.push(
          new vscode.DocumentSymbol(
            nameToken.text,
            next.kind.replace("KW_", ""),
            keywordToSymbolKind(next.kind),
            range,
            range,
          ),
        );
      }
      continue;
    }

    if (DECLARATION_KEYWORDS.has(token.kind)) {
      const prev = i > 0 ? tokenArr[i - 1] : undefined;
      if (prev && (prev.kind === "KW_pub" || prev.kind === "KW_export")) {
        continue;
      }
      const nameToken = tokenArr[i + 1];
      if (nameToken && IDENT_KINDS.has(nameToken.kind)) {
        const range = new vscode.Range(
          new vscode.Position(nameToken.line - 1, nameToken.col - 1),
          new vscode.Position(nameToken.line - 1, nameToken.col - 1 + nameToken.text.length),
        );
        symbols.push(
          new vscode.DocumentSymbol(
            nameToken.text,
            token.kind.replace("KW_", ""),
            keywordToSymbolKind(token.kind),
            range,
            range,
          ),
        );
      }
    }
  }

  return symbols;
};

/** Cache entry keyed by document URI + version. */
type CacheEntry = {
  readonly version: number;
  readonly symbols: ReadonlyArray<vscode.DocumentSymbol>;
};

/** Create a KGF-based DocumentSymbolProvider with per-document-version caching. */
export const createOutlineProvider = (getClient: () => HttpClient | undefined): vscode.DocumentSymbolProvider => {
  const cache = new Map<string, CacheEntry>();

  return {
    provideDocumentSymbols: async (
      document: vscode.TextDocument,
      token: vscode.CancellationToken,
    ): Promise<Array<vscode.DocumentSymbol>> => {
      const client = getClient();
      if (!client) {
        return [];
      }

      const cacheKey = document.uri.toString();
      const cached = cache.get(cacheKey);
      if (cached && cached.version === document.version) {
        return [...cached.symbols];
      }

      const abortController = new AbortController();
      token.onCancellationRequested(() => abortController.abort());

      const result = await tokenizeFile(client, { file: document.uri.fsPath }, abortController.signal);
      if (!result.ok) {
        return [];
      }

      const symbols = tokensToSymbols(result.data);
      cache.set(cacheKey, { version: document.version, symbols });
      return symbols;
    },
  };
};
