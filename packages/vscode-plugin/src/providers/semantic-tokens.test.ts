/**
 * @file Tests for the semantic tokens provider.
 */

vi.mock("@indexion/api-client", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@indexion/api-client")>();
  return { ...actual, tokenizeFile: vi.fn() };
});

import { createSemanticTokensProvider, SEMANTIC_TOKEN_LEGEND } from "./semantic-tokens.ts";
import { tokenizeFile } from "@indexion/api-client";
import type { KgfToken } from "@indexion/api-client";
import { MOCK_CLIENT, mockDocument, mockToken } from "./test-helpers.ts";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("SEMANTIC_TOKEN_LEGEND", () => {
  it("contains expected token types", () => {
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("keyword");
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("variable");
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("type");
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("string");
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("comment");
    expect(SEMANTIC_TOKEN_LEGEND.tokenTypes).toContain("function");
  });

  it("contains expected modifiers", () => {
    expect(SEMANTIC_TOKEN_LEGEND.tokenModifiers).toContain("declaration");
    expect(SEMANTIC_TOKEN_LEGEND.tokenModifiers).toContain("documentation");
  });
});

describe("createSemanticTokensProvider", () => {
  it("returns undefined when a dedicated grammar exists", async () => {
    const tsDocument = { ...mockDocument, languageId: "typescript" } as unknown as typeof mockDocument;
    const provider = createSemanticTokensProvider(() => MOCK_CLIENT);
    const result = await provider.provideDocumentSemanticTokens(tsDocument, mockToken);
    expect(result).toBeUndefined();
    expect(tokenizeFile).not.toHaveBeenCalled();
  });

  it("returns undefined when no config", async () => {
    const provider = createSemanticTokensProvider(() => undefined);
    const result = await provider.provideDocumentSemanticTokens(mockDocument, mockToken);
    expect(result).toBeUndefined();
  });

  it("returns undefined when bridge fails", async () => {
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: false, error: "fail" });
    const provider = createSemanticTokensProvider(() => MOCK_CLIENT);
    const result = await provider.provideDocumentSemanticTokens(mockDocument, mockToken);
    expect(result).toBeUndefined();
  });

  it("builds semantic tokens from KGF tokens", async () => {
    const tokens: KgfToken[] = [
      { kind: "KW_fn", text: "fn", line: 1, col: 1 },
      { kind: "Ident", text: "main", line: 1, col: 4 },
      { kind: "String", text: '"hello"', line: 2, col: 3 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createSemanticTokensProvider(() => MOCK_CLIENT);
    const result = await provider.provideDocumentSemanticTokens(mockDocument, mockToken);

    expect(result).toBeDefined();
    expect(result!.data).toBeInstanceOf(Uint32Array);
  });

  it("skips tokens with unknown kinds", async () => {
    const tokens: KgfToken[] = [
      { kind: "LParen", text: "(", line: 1, col: 1 },
      { kind: "RParen", text: ")", line: 1, col: 2 },
    ];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createSemanticTokensProvider(() => MOCK_CLIENT);
    const result = await provider.provideDocumentSemanticTokens(mockDocument, mockToken);

    // Should still return a result, just with no tokens pushed
    expect(result).toBeDefined();
  });

  it("skips tokens with invalid positions", async () => {
    const tokens: KgfToken[] = [{ kind: "KW_fn", text: "fn", line: 0, col: 0 }];
    (tokenizeFile as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: tokens });

    const provider = createSemanticTokensProvider(() => MOCK_CLIENT);
    const result = await provider.provideDocumentSemanticTokens(mockDocument, mockToken);
    expect(result).toBeDefined();
  });
});
