/**
 * @file Tests for the wiki TreeDataProvider.
 *
 * Same pattern as KGF list provider tests.
 */

import { describe, it, expect, vi } from "vitest";
import type { HttpClient, ApiResponse } from "@indexion/api-client";
import { createWikiTreeProvider } from "./provider.ts";
import type { WikiTreeItem } from "./items.ts";

const mockClient = (nav?: unknown, navError?: string): HttpClient => {
  const get = vi.fn(async (path: string): Promise<ApiResponse<unknown>> => {
    if (path === "/wiki/nav") {
      if (navError) {
        return { ok: false, error: navError };
      }
      return { ok: true, data: nav ?? { pages: [] } };
    }
    return { ok: false, error: "unknown" };
  });
  return { get, post: vi.fn() } as unknown as HttpClient;
};

const getChildren = async (
  provider: ReturnType<typeof createWikiTreeProvider>,
  element?: WikiTreeItem,
): Promise<Array<WikiTreeItem>> => {
  const result = await provider.getChildren(element);
  return result as Array<WikiTreeItem>;
};

describe("createWikiTreeProvider", () => {
  it("returns empty when client is undefined", async () => {
    const provider = createWikiTreeProvider(() => undefined);
    const children = await getChildren(provider);
    expect(children).toEqual([]);
  });

  it("returns empty when API fails", async () => {
    const client = mockClient(undefined, "connection refused");
    const provider = createWikiTreeProvider(() => client);
    const children = await getChildren(provider);
    expect(children).toEqual([]);
  });

  it("returns top-level pages", async () => {
    const nav = {
      pages: [
        { id: "overview", title: "Overview", children: [] },
        { id: "getting-started", title: "Getting Started", children: [] },
      ],
    };
    const client = mockClient(nav);
    const provider = createWikiTreeProvider(() => client);
    const children = await getChildren(provider);
    expect(children).toHaveLength(2);
    expect(children[0]?.id).toBe("overview");
    expect(children[1]?.id).toBe("getting-started");
  });

  it("returns nested children", async () => {
    const nav = {
      pages: [
        {
          id: "arch",
          title: "Architecture",
          children: [
            { id: "kgf", title: "KGF", children: [] },
            { id: "core", title: "Core", children: [] },
          ],
        },
      ],
    };
    const client = mockClient(nav);
    const provider = createWikiTreeProvider(() => client);
    const roots = await getChildren(provider);
    expect(roots).toHaveLength(1);
    expect(roots[0]?.children).toHaveLength(2);

    const archChildren = await getChildren(provider, roots[0]!);
    expect(archChildren).toHaveLength(2);
    expect(archChildren[0]?.id).toBe("kgf");
  });
});
