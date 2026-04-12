/**
 * @file Tests for server lifecycle — health polling and client creation.
 *
 * These tests verify the health-polling logic in isolation.
 * The actual spawn is not tested here (that requires integration tests).
 */

import { describe, it, expect, vi } from "vitest";
import { createHttpClient } from "@indexion/api-client";

/** Options for pollForHealth. */
type PollOptions = {
  readonly baseUrl: string;
  readonly maxAttempts: number;
  readonly intervalMs: number;
  readonly fetchFn: typeof fetch;
};

/**
 * Extract and test the health-polling logic independently.
 * Returns a client when health responds 200, or undefined on timeout.
 */
const pollForHealth = async (options: PollOptions): Promise<ReturnType<typeof createHttpClient> | undefined> => {
  for (let i = 0; i < options.maxAttempts; i++) {
    try {
      const res = await options.fetchFn(`${options.baseUrl}/health`);
      if (res.ok) {
        return createHttpClient(options.baseUrl);
      }
    } catch {
      // not ready
    }
    await new Promise((r) => setTimeout(r, options.intervalMs));
  }
  return undefined;
};

describe("pollForHealth", () => {
  it("returns client on immediate success", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    const client = await pollForHealth({
      baseUrl: "http://localhost:1234/api",
      maxAttempts: 5,
      intervalMs: 10,
      fetchFn: mockFetch as unknown as typeof fetch,
    });
    expect(client).toBeDefined();
    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch).toHaveBeenCalledWith("http://localhost:1234/api/health");
  });

  it("retries until success", async () => {
    const mockFetch = vi
      .fn()
      .mockRejectedValueOnce(new Error("ECONNREFUSED"))
      .mockRejectedValueOnce(new Error("ECONNREFUSED"))
      .mockResolvedValueOnce({ ok: true });

    const client = await pollForHealth({
      baseUrl: "http://localhost:5678/api",
      maxAttempts: 5,
      intervalMs: 10,
      fetchFn: mockFetch as unknown as typeof fetch,
    });
    expect(client).toBeDefined();
    expect(mockFetch).toHaveBeenCalledTimes(3);
  });

  it("returns undefined on timeout", async () => {
    const mockFetch = vi.fn().mockRejectedValue(new Error("ECONNREFUSED"));
    const client = await pollForHealth({
      baseUrl: "http://localhost:9999/api",
      maxAttempts: 3,
      intervalMs: 10,
      fetchFn: mockFetch as unknown as typeof fetch,
    });
    expect(client).toBeUndefined();
    expect(mockFetch).toHaveBeenCalledTimes(3);
  });

  it("retries on non-ok response", async () => {
    const mockFetch = vi.fn().mockResolvedValueOnce({ ok: false, status: 503 }).mockResolvedValueOnce({ ok: true });

    const client = await pollForHealth({
      baseUrl: "http://localhost:4321/api",
      maxAttempts: 5,
      intervalMs: 10,
      fetchFn: mockFetch as unknown as typeof fetch,
    });
    expect(client).toBeDefined();
    expect(mockFetch).toHaveBeenCalledTimes(2);
  });
});
