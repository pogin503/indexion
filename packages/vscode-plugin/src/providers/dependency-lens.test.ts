/**
 * @file Tests for the dependency lens (CodeLens) provider.
 */

vi.mock("@indexion/api-client", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@indexion/api-client")>();
  return { ...actual, extractEdges: vi.fn() };
});

import { createDependencyLensProvider } from "./dependency-lens.ts";
import { extractEdges } from "@indexion/api-client";
import type { KgfEdge } from "@indexion/api-client";
import { MOCK_CLIENT, mockDocument, mockToken } from "./test-helpers.ts";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("createDependencyLensProvider", () => {
  it("returns empty when no config", async () => {
    const provider = createDependencyLensProvider(() => undefined);
    const lenses = await provider.provideCodeLenses!(mockDocument, mockToken);
    expect(lenses).toEqual([]);
  });

  it("returns empty when bridge fails", async () => {
    (extractEdges as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: false, error: "fail" });
    const provider = createDependencyLensProvider(() => MOCK_CLIENT);
    const lenses = await provider.provideCodeLenses!(mockDocument, mockToken);
    expect(lenses).toEqual([]);
  });

  it("returns empty when no import edges", async () => {
    const edges: KgfEdge[] = [{ from: "a.ts", to: "b.ts", kind: "Calls" }];
    (extractEdges as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: edges });

    const provider = createDependencyLensProvider(() => MOCK_CLIENT);
    const lenses = await provider.provideCodeLenses!(mockDocument, mockToken);
    expect(lenses).toEqual([]);
  });

  it("shows dependency count for Imports edges", async () => {
    const edges: KgfEdge[] = [
      { from: "main.ts", to: "utils.ts", kind: "Imports" },
      { from: "main.ts", to: "config.ts", kind: "Imports" },
      { from: "main.ts", to: "types.ts", kind: "ModuleDependsOn" },
    ];
    (extractEdges as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: edges });

    const provider = createDependencyLensProvider(() => MOCK_CLIENT);
    const lenses = await provider.provideCodeLenses!(mockDocument, mockToken);

    expect(lenses).toHaveLength(1);
    expect(lenses![0].command!.title).toBe("3 dependencies");
  });

  it("deduplicates dependencies", async () => {
    const edges: KgfEdge[] = [
      { from: "main.ts", to: "utils.ts", kind: "Imports" },
      { from: "main.ts", to: "utils.ts", kind: "ModuleDependsOn" },
    ];
    (extractEdges as ReturnType<typeof vi.fn>).mockResolvedValue({ ok: true, data: edges });

    const provider = createDependencyLensProvider(() => MOCK_CLIENT);
    const lenses = await provider.provideCodeLenses!(mockDocument, mockToken);

    expect(lenses![0].command!.title).toBe("1 dependencies");
  });
});
