/**
 * @file Tests for the outline (DocumentSymbol) provider.
 */

import * as vscode from "vscode";

vi.mock("@indexion/api-client", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@indexion/api-client")>();
  return { ...actual, tokenizeFile: vi.fn() };
});

import { createOutlineProvider } from "./outline.ts";
import { tokenizeFile } from "@indexion/api-client";
import type { KgfToken } from "@indexion/api-client";
import { MOCK_CLIENT, mockDocument, mockToken } from "./test-helpers.ts";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("createOutlineProvider", () => {
  it("returns empty array when no config", async () => {
    const provider = createOutlineProvider(() => undefined);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);
    expect(symbols).toEqual([]);
  });

  it("returns empty array when bridge fails", async () => {
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: false, error: "fail" });
    const provider = createOutlineProvider(() => MOCK_CLIENT);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);
    expect(symbols).toEqual([]);
  });

  it("extracts pub fn as Function symbol", async () => {
    const tokens: KgfToken[] = [
      { kind: "KW_pub", text: "pub", line: 1, col: 1 },
      { kind: "KW_fn", text: "fn", line: 1, col: 5 },
      { kind: "Ident", text: "main", line: 1, col: 8 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createOutlineProvider(() => MOCK_CLIENT);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);

    expect(symbols).toHaveLength(1);
    expect(symbols![0].name).toBe("main");
    expect(symbols![0].kind).toBe(vscode.SymbolKind.Function);
  });

  it("extracts standalone fn", async () => {
    const tokens: KgfToken[] = [
      { kind: "KW_fn", text: "fn", line: 3, col: 1 },
      { kind: "Ident", text: "helper", line: 3, col: 4 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createOutlineProvider(() => MOCK_CLIENT);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);

    expect(symbols).toHaveLength(1);
    expect(symbols![0].name).toBe("helper");
  });

  it("extracts struct and enum", async () => {
    const tokens: KgfToken[] = [
      { kind: "KW_struct", text: "struct", line: 1, col: 1 },
      { kind: "UpperIdent", text: "Config", line: 1, col: 8 },
      { kind: "KW_enum", text: "enum", line: 5, col: 1 },
      { kind: "UpperIdent", text: "Status", line: 5, col: 6 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createOutlineProvider(() => MOCK_CLIENT);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);

    expect(symbols).toHaveLength(2);
    expect(symbols![0].name).toBe("Config");
    expect(symbols![0].kind).toBe(vscode.SymbolKind.Struct);
    expect(symbols![1].name).toBe("Status");
    expect(symbols![1].kind).toBe(vscode.SymbolKind.Enum);
  });

  it("skips non-declaration tokens", async () => {
    const tokens: KgfToken[] = [
      { kind: "Ident", text: "x", line: 1, col: 1 },
      { kind: "Operator", text: "=", line: 1, col: 3 },
      { kind: "Number", text: "42", line: 1, col: 5 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createOutlineProvider(() => MOCK_CLIENT);
    const symbols = await provider.provideDocumentSymbols(mockDocument, mockToken);

    expect(symbols).toHaveLength(0);
  });

  it("uses cache on same document version", async () => {
    const tokens: KgfToken[] = [
      { kind: "KW_fn", text: "fn", line: 1, col: 1 },
      { kind: "Ident", text: "cached", line: 1, col: 4 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createOutlineProvider(() => MOCK_CLIENT);
    await provider.provideDocumentSymbols(mockDocument, mockToken);
    await provider.provideDocumentSymbols(mockDocument, mockToken);

    // Bridge should only be called once due to caching
    expect(tokenizeFile).toHaveBeenCalledTimes(1);
  });
});
