/**
 * @file Tests for extension activation — verifies that all commands, providers,
 * and views declared in package.json are registered on activate().
 *
 * This is the guard that ensures the extension will actually load in VS Code.
 */

import * as vscode from "vscode";
import fs from "node:fs";
import path from "node:path";
import { activate, deactivate } from "./extension.ts";

/** Read package.json contributes to get declared command IDs and view IDs. */
const loadPackageJson = () => {
  const raw = fs.readFileSync(path.resolve(__dirname, "../package.json"), "utf-8");
  return JSON.parse(raw) as {
    contributes: {
      commands: Array<{ command: string }>;
      views: Record<string, Array<{ id: string }>>;
      viewsContainers: Record<string, Array<{ id: string }>>;
    };
    activationEvents: string[];
    main: string;
  };
};

/** Fake ExtensionContext that collects subscriptions. */
const createMockContext = () => {
  const subscriptions: Array<{ dispose: () => void }> = [];
  return {
    subscriptions,
    extensionUri: vscode.Uri.file("/fake/extension"),
    extensionPath: "/fake/extension",
    globalState: { get: () => undefined, update: async () => {} },
    workspaceState: { get: () => undefined, update: async () => {} },
    asAbsolutePath: (p: string) => `/fake/extension/${p}`,
  } as unknown as vscode.ExtensionContext;
};

describe("package.json integrity", () => {
  const pkg = loadPackageJson();

  it("declares main entry point as dist/extension.js", () => {
    expect(pkg.main).toBe("dist/extension.js");
  });

  it("has onStartupFinished activation event", () => {
    expect(pkg.activationEvents).toContain("onStartupFinished");
  });

  it("declares at least one command", () => {
    expect(pkg.contributes.commands.length).toBeGreaterThan(0);
  });

  it("declares all activity bar containers", () => {
    const containers = pkg.contributes.viewsContainers?.activitybar ?? [];
    const ids = containers.map((c: { id: string }) => c.id);
    expect(ids).toContain("indexionSearch");
    expect(ids).toContain("indexionAnalysis");
    expect(ids).toContain("indexionKgf");
    expect(ids).toContain("indexionWiki");
  });

  it("declares all sidebar views", () => {
    const viewIds = Object.values(pkg.contributes.views)
      .flat()
      .map((v) => v.id);
    expect(viewIds).toContain("indexion.search");
    expect(viewIds).toContain("indexion.kgfList");
    expect(viewIds).toContain("indexion.explore");
    expect(viewIds).toContain("indexion.plans");
    expect(viewIds).toContain("indexion.wiki");
  });
});

describe("activate", () => {
  const pkg = loadPackageJson();
  const declaredCommandIds = pkg.contributes.commands.map((c) => c.command);

  it("registers all commands declared in package.json", () => {
    const registerSpy = vi.spyOn(vscode.commands, "registerCommand");
    const ctx = createMockContext();

    activate(ctx);

    const registeredIds = registerSpy.mock.calls.map((call) => call[0]);

    for (const id of declaredCommandIds) {
      expect(registeredIds, `Missing command registration: ${id}`).toContain(id);
    }

    registerSpy.mockRestore();
  });

  it("registers tree data providers and webview view providers", () => {
    const registerTreeSpy = vi.spyOn(vscode.window, "registerTreeDataProvider");
    const registerWebviewSpy = vi.spyOn(vscode.window, "registerWebviewViewProvider");
    const ctx = createMockContext();

    activate(ctx);

    const registeredTreeIds = registerTreeSpy.mock.calls.map((call) => call[0]);
    expect(registeredTreeIds).toContain("indexion.kgfList");
    expect(registeredTreeIds).toContain("indexion.plans");

    const registeredWebviewIds = registerWebviewSpy.mock.calls.map((call) => call[0]);
    expect(registeredWebviewIds).toContain("indexion.search");
    expect(registeredWebviewIds).toContain("indexion.explore");
    expect(registeredWebviewIds).toContain("indexion.wiki");

    registerTreeSpy.mockRestore();
    registerWebviewSpy.mockRestore();
  });

  it("registers language providers (outline, semantic tokens, code lens)", () => {
    const symbolSpy = vi.spyOn(vscode.languages, "registerDocumentSymbolProvider");
    const semanticSpy = vi.spyOn(vscode.languages, "registerDocumentSemanticTokensProvider");
    const lensSpy = vi.spyOn(vscode.languages, "registerCodeLensProvider");
    const ctx = createMockContext();

    activate(ctx);

    expect(symbolSpy).toHaveBeenCalledTimes(1);
    expect(semanticSpy).toHaveBeenCalledTimes(1);
    expect(lensSpy).toHaveBeenCalledTimes(1);

    symbolSpy.mockRestore();
    semanticSpy.mockRestore();
    lensSpy.mockRestore();
  });

  it("pushes disposables to context.subscriptions", () => {
    const ctx = createMockContext();
    activate(ctx);
    // commands (12 from COMMAND_MAP + kgfList + openSettings) + 3 language providers = 17
    expect(ctx.subscriptions.length).toBeGreaterThanOrEqual(15);
  });
});

describe("deactivate", () => {
  it("does not throw", () => {
    expect(() => deactivate()).not.toThrow();
  });
});
