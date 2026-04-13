/**
 * @file Shared test setup for provider tests (SoT for mock client, document, token).
 */

import * as vscode from "vscode";
import type { HttpClient } from "@indexion/api-client";

export const MOCK_CLIENT: HttpClient = {
  get: async () => ({ ok: false as const, error: "mock" }),
  post: async () => ({ ok: false as const, error: "mock" }),
};

export const mockDocument = {
  uri: { toString: () => "file:///workspace/test.mbt", fsPath: "/workspace/test.mbt" },
  languageId: "plaintext",
  version: 1,
} as unknown as vscode.TextDocument;

export const mockToken = {
  isCancellationRequested: false,
  onCancellationRequested: () => ({ dispose: () => {} }),
} as unknown as vscode.CancellationToken;
