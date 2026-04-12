/**
 * @file Tests for the wiki sidebar WebviewViewProvider.
 *
 * Verifies the coordination between:
 * - WebviewBridge handshake (ready → flush)
 * - Server readiness (notifyServerStatus)
 * - Data loading (loadNav, handleSearch)
 * - Navigation callback (onNavigate)
 */

import { describe, it, expect, vi } from "vitest";
import type { HttpClient, ApiResponse } from "@indexion/api-client";
import { createWikiViewProvider } from "./provider.ts";
import type { WikiToWebview } from "./messages.ts";

// ─── Test helpers ───────────────────────────────────────

type MockOverrides = {
  readonly nav?: unknown;
  readonly search?: unknown;
  readonly navError?: string;
  readonly searchError?: string;
};

const dispatchGet = (path: string, o?: MockOverrides): ApiResponse<unknown> => {
  if (path === "/wiki/nav") {
    return o?.navError ? { ok: false, error: o.navError } : { ok: true, data: o?.nav ?? { pages: [] } };
  }
  return { ok: false, error: "unknown path" };
};

const dispatchPost = (path: string, o?: MockOverrides): ApiResponse<unknown> => {
  if (path === "/wiki/search") {
    return o?.searchError ? { ok: false, error: o.searchError } : { ok: true, data: o?.search ?? [] };
  }
  return { ok: false, error: "unknown path" };
};

const mockClient = (o?: MockOverrides): HttpClient => {
  const get = vi.fn(async (path: string) => dispatchGet(path, o));
  const post = vi.fn(async (path: string) => dispatchPost(path, o));
  return { get, post } as unknown as HttpClient;
};

const EXT_URI = { fsPath: "/ext" } as import("vscode").Uri;

/** Shorthand for creating the provider with options. */
const makeProvider = (opts: {
  readonly getClient: () => HttpClient | undefined;
  readonly onNavigate?: (pageId: string) => void;
  readonly log?: { readonly appendLine: (msg: string) => void };
}) =>
  createWikiViewProvider({
    extensionUri: EXT_URI,
    getClient: opts.getClient,
    onNavigate: opts.onNavigate ?? vi.fn(),
    log: opts.log,
  });

const createMockView = () => {
  const posted: Array<unknown> = [];
  const messageHandlers: Array<(msg: { type: string; [key: string]: unknown }) => void> = [];

  const view = {
    webview: {
      options: {},
      html: "",
      postMessage: vi.fn((msg: unknown) => {
        posted.push(msg);
        return true;
      }),
      onDidReceiveMessage: (handler: (msg: { type: string }) => void) => {
        messageHandlers.push(handler);
        return { dispose: () => {} };
      },
      asWebviewUri: (uri: unknown) => uri,
      cspSource: "https://example.com",
    },
  } as unknown as import("vscode").WebviewView;

  const simulateMessage = (msg: { type: string; [key: string]: unknown }): void => {
    for (const handler of messageHandlers) {
      handler(msg);
    }
  };

  return { view, posted, simulateMessage, simulateReady: () => simulateMessage({ type: "ready" }) };
};

const messagesOfType = <T extends WikiToWebview["type"]>(
  posted: ReadonlyArray<unknown>,
  type: T,
): ReadonlyArray<Extract<WikiToWebview, { type: T }>> =>
  posted.filter(
    (m): m is Extract<WikiToWebview, { type: T }> =>
      typeof m === "object" && m !== null && (m as { type: string }).type === type,
  );

const flush = async (): Promise<void> => {
  await new Promise((r) => setTimeout(r, 0));
};

// ─── Tests ──────────────────────────────────────────────

describe("createWikiViewProvider", () => {
  it("loads nav when webview opens and server is already ready", async () => {
    const client = mockClient({ nav: { pages: [{ id: "overview", title: "Overview", children: [] }] } });
    const log = { appendLine: vi.fn() };
    const provider = makeProvider({ getClient: () => client, log });

    provider.notifyServerStatus(true);

    const { view, posted, simulateReady } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    expect(messagesOfType(posted, "serverStatus").some((m) => m.ready)).toBe(true);
    expect(messagesOfType(posted, "navLoaded")).toHaveLength(1);
    expect(messagesOfType(posted, "navLoaded")[0]?.nav.pages[0]?.id).toBe("overview");

    const logs = log.appendLine.mock.calls.map((c) => c[0]);
    expect(logs).toContainEqual(expect.stringContaining("[wiki] bridge onReady: hasClient=true"));
    expect(logs).toContainEqual(expect.stringContaining("[wiki] loadNav: fetching..."));
  });

  it("loads nav when server becomes ready after webview is open", async () => {
    const realClient = mockClient({ nav: { pages: [{ id: "arch", title: "Architecture", children: [] }] } });
    const clientRef: { current: HttpClient | undefined } = { current: undefined };
    const provider = makeProvider({ getClient: () => clientRef.current });

    const { view, posted, simulateReady } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    expect(messagesOfType(posted, "serverStatus").every((m) => !m.ready)).toBe(true);
    expect(messagesOfType(posted, "navLoaded")).toHaveLength(0);

    clientRef.current = realClient;
    provider.notifyServerStatus(true);
    await flush();

    expect(messagesOfType(posted, "serverStatus").some((m) => m.ready)).toBe(true);
    expect(messagesOfType(posted, "navLoaded")).toHaveLength(1);
  });

  it("sends error when nav API fails", async () => {
    const client = mockClient({ navError: "connection refused" });
    const provider = makeProvider({ getClient: () => client, log: { appendLine: vi.fn() } });

    const { view, posted, simulateReady } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    expect(messagesOfType(posted, "error").find((e) => e.target === "nav")?.message).toBe("connection refused");
  });

  it("calls onNavigate when navigate message is received", async () => {
    const client = mockClient({ nav: { pages: [] } });
    const onNavigate = vi.fn();
    const provider = makeProvider({ getClient: () => client, onNavigate });

    const { view, simulateReady, simulateMessage } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    simulateMessage({ type: "navigate", pageId: "kgf-system" });

    expect(onNavigate).toHaveBeenCalledOnce();
    expect(onNavigate).toHaveBeenCalledWith("kgf-system");
  });

  it("handles search and converts results to WikiSearchHit", async () => {
    const client = mockClient({
      nav: { pages: [] },
      search: [{ id: "page-1", title: "Overview", snippet: "intro text" }, { id: "page-2" }],
    });
    const provider = makeProvider({ getClient: () => client });

    const { view, posted, simulateReady, simulateMessage } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    simulateMessage({ type: "search", query: "overview" });
    await flush();

    const searchMsgs = messagesOfType(posted, "searchResults");
    expect(searchMsgs).toHaveLength(1);
    expect(searchMsgs[0]?.results).toHaveLength(2);
    expect(searchMsgs[0]?.results[0]).toEqual({ id: "page-1", title: "Overview", snippet: "intro text" });
  });

  it("sends error when search API fails", async () => {
    const client = mockClient({ nav: { pages: [] }, searchError: "timeout" });
    const provider = makeProvider({ getClient: () => client });

    const { view, posted, simulateReady, simulateMessage } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    simulateMessage({ type: "search", query: "test" });
    await flush();

    expect(messagesOfType(posted, "error").find((e) => e.target === "search")?.message).toBe("timeout");
  });

  it("reloads nav on requestNav message", async () => {
    const client = mockClient({ nav: { pages: [{ id: "p1", title: "Page 1", children: [] }] } });
    const provider = makeProvider({ getClient: () => client });

    const { view, posted, simulateReady, simulateMessage } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    expect(messagesOfType(posted, "navLoaded")).toHaveLength(1);
    simulateMessage({ type: "requestNav" });
    await flush();
    expect(messagesOfType(posted, "navLoaded")).toHaveLength(2);
  });

  it("sends loading indicator before nav fetch", async () => {
    const client = mockClient({ nav: { pages: [] } });
    const provider = makeProvider({ getClient: () => client });

    const { view, posted, simulateReady } = createMockView();
    provider.resolveWebviewView(view, {} as never, {} as never);
    simulateReady();
    await flush();

    expect(messagesOfType(posted, "loading").filter((m) => m.target === "nav").length).toBeGreaterThanOrEqual(1);
  });

  it("does not crash when notifyServerStatus is called before attach", () => {
    const provider = makeProvider({ getClient: () => undefined });
    expect(() => provider.notifyServerStatus(true)).not.toThrow();
  });
});
