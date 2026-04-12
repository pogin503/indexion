/**
 * @file Tests for KGF list TreeDataProvider.
 */

import { describe, it, expect, vi } from "vitest";
import type { HttpClient } from "@indexion/api-client";
import { createKgfListProvider } from "./provider.ts";
import type { KgfTreeItem } from "./items.ts";

const mockClient = (data: unknown): HttpClient => ({
  get: vi.fn().mockResolvedValue({ ok: true, data }),
  post: vi.fn(),
});

const failClient = (): HttpClient => ({
  get: vi.fn().mockResolvedValue({ ok: false, error: "connection refused" }),
  post: vi.fn(),
});

/** Get root children, asserting non-null. */
const getRootChildren = async (provider: ReturnType<typeof createKgfListProvider>): Promise<Array<KgfTreeItem>> => {
  const result = await provider.getChildren(undefined);
  return result as Array<KgfTreeItem>;
};

/** Get children of a tree item, asserting non-null. */
const getItemChildren = async (
  provider: ReturnType<typeof createKgfListProvider>,
  item: KgfTreeItem,
): Promise<Array<KgfTreeItem>> => {
  const result = await provider.getChildren(item);
  return result as Array<KgfTreeItem>;
};

/** Find a category by name from a list of items. */
const findCategory = (items: ReadonlyArray<KgfTreeItem>, name: string): KgfTreeItem => {
  const found = items.find((c) => c.type === "category" && c.name === name);
  if (!found) {
    throw new Error(
      `Category "${name}" not found in [${items.map((i) => (i.type === "category" ? i.name : "")).join(", ")}]`,
    );
  }
  return found;
};

describe("createKgfListProvider", () => {
  it("returns empty when client is undefined", async () => {
    const provider = createKgfListProvider(() => undefined);
    const children = await getRootChildren(provider);
    expect(children).toEqual([]);
  });

  it("returns empty when API fails", async () => {
    const client = failClient();
    const provider = createKgfListProvider(() => client);
    const children = await getRootChildren(provider);
    expect(children).toEqual([]);
    expect(client.get).toHaveBeenCalledOnce();
  });

  it("groups specs by category", async () => {
    const specs = [
      { name: "typescript", category: "programming", sources: [".ts"] },
      { name: "python", category: "programming", sources: [".py"] },
      { name: "css", category: "dsl", sources: [".css"] },
    ];
    const client = mockClient(specs);
    const provider = createKgfListProvider(() => client);

    const categories = await getRootChildren(provider);
    expect(categories).toHaveLength(2);
    expect(categories).toMatchObject([
      { type: "category", name: "programming" },
      { type: "category", name: "dsl" },
    ]);

    const progSpecs = await getItemChildren(provider, findCategory(categories, "programming"));
    expect(progSpecs).toHaveLength(2);
    expect(progSpecs).toMatchObject([
      { type: "spec", spec: { name: "typescript" } },
      { type: "spec", spec: { name: "python" } },
    ]);
  });

  it("puts uncategorized specs under 'other'", async () => {
    const specs = [{ name: "universal", category: "", sources: [".txt"] }];
    const client = mockClient(specs);
    const provider = createKgfListProvider(() => client);
    const categories = await getRootChildren(provider);
    expect(categories).toHaveLength(1);
    expect(categories).toMatchObject([{ type: "category", name: "other" }]);
  });

  it("refresh triggers new fetch", async () => {
    const specs1 = [{ name: "go", category: "programming", sources: [".go"] }];
    const specs2 = [
      { name: "go", category: "programming", sources: [".go"] },
      { name: "rust", category: "programming", sources: [".rs"] },
    ];
    // refresh() eagerly calls loadSpecs(), then getChildren also calls loadSpecs().
    // Provide enough mock responses for both.
    const getFn = vi
      .fn()
      .mockResolvedValueOnce({ ok: true, data: specs1 }) // getChildren #1
      .mockResolvedValueOnce({ ok: true, data: specs2 }) // refresh -> loadSpecs
      .mockResolvedValueOnce({ ok: true, data: specs2 }); // getChildren #2
    const client: HttpClient = { get: getFn, post: vi.fn() };
    const provider = createKgfListProvider(() => client);

    const cats1 = await getRootChildren(provider);
    const children1 = await getItemChildren(provider, findCategory(cats1, "programming"));
    expect(children1).toHaveLength(1);

    provider.refresh();
    // Wait for the eager loadSpecs inside refresh to complete
    await new Promise((r) => setTimeout(r, 10));
    const cats2 = await getRootChildren(provider);
    const children2 = await getItemChildren(provider, findCategory(cats2, "programming"));
    expect(children2).toHaveLength(2);
  });
});
