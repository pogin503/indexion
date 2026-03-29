/**
 * @file API client - typed fetch wrapper.
 */

export type ApiResponse<T> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: string };

const BASE_URL = "/api";

export const apiGet = async <T>(path: string, signal?: AbortSignal): Promise<ApiResponse<T>> => {
  try {
    const res = await fetch(`${BASE_URL}${path}`, { signal });
    const json = (await res.json()) as ApiResponse<T>;
    return json;
  } catch (err) {
    if (err instanceof DOMException && err.name === "AbortError") {
      return { ok: false, error: "Request aborted" };
    }
    return { ok: false, error: err instanceof Error ? err.message : "Unknown error" };
  }
};

export const apiPost = async <T>(path: string, body: unknown, signal?: AbortSignal): Promise<ApiResponse<T>> => {
  try {
    const res = await fetch(`${BASE_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal,
    });
    const json = (await res.json()) as ApiResponse<T>;
    return json;
  } catch (err) {
    if (err instanceof DOMException && err.name === "AbortError") {
      return { ok: false, error: "Request aborted" };
    }
    return { ok: false, error: err instanceof Error ? err.message : "Unknown error" };
  }
};
