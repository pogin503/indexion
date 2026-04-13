/**
 * @file Re-export React hooks from @indexion/api-client + app-level cached variant.
 */

import { useEffect, useMemo, useSyncExternalStore } from "react";
import type { ApiResponse } from "@indexion/api-client";
import {
  cachedFetch,
  getCachedResult,
  getCacheVersion,
  subscribe,
  type CacheKeyValue,
} from "./api-cache.ts";

export type { ApiState } from "@indexion/api-client/react";
export { useApiCall, useApiMutationCall } from "@indexion/api-client/react";

type CachedState<T> =
  | { readonly status: "loading" }
  | { readonly status: "success"; readonly data: T }
  | { readonly status: "error"; readonly error: string };

/**
 * Like useApiCall but backed by the app-level cache.
 * Same key → same data across all components and page navigations.
 * Automatically re-fetches when the cache is invalidated (e.g. after rebuild).
 *
 * Uses useSyncExternalStore to derive state from the cache — no setState
 * in useEffect. The effect only initiates the fetch (side effect); the
 * cache notifies subscribers when the result is available.
 */
export const useCachedApiCall = <T>(
  key: CacheKeyValue,
  fetch: () => Promise<ApiResponse<T>>,
): CachedState<T> => {
  const version = useSyncExternalStore(subscribe, getCacheVersion);

  // Initiate fetch (idempotent — cachedFetch deduplicates)
  useEffect(() => {
    cachedFetch(key, fetch);
  }, [key, version]);

  // Derive state from cache synchronously
  return useMemo((): CachedState<T> => {
    void version;
    const result = getCachedResult<T>(key);
    if (!result) {
      return { status: "loading" };
    }
    if (result.ok) {
      return { status: "success", data: result.data };
    }
    return { status: "error", error: result.error };
  }, [key, version]);
};
