/**
 * @file React hooks for @indexion/api-client.
 *
 * Generic hooks that accept typed api-client functions, so that
 * endpoint URLs are never hard-coded in page components.
 */

import { useState, useEffect, useCallback, useRef } from "react";
import type { ApiResponse } from "./types.ts";

export type ApiState<T> =
  | { readonly status: "idle" }
  | { readonly status: "loading" }
  | { readonly status: "success"; readonly data: T }
  | { readonly status: "error"; readonly error: string };

/**
 * Fetch data via a typed api-client function.
 *
 * @param call - `(signal) => Promise<ApiResponse<T>>`, or `null` to skip.
 *               Re-fetches whenever the *identity* of `call` changes, so
 *               callers should wrap with `useCallback` when the function
 *               captures reactive values (e.g. a page id).
 */
export const useApiCall = <T>(
  call: ((signal: AbortSignal) => Promise<ApiResponse<T>>) | null,
): ApiState<T> => {
  const [state, setState] = useState<ApiState<T>>({ status: "idle" });

  useEffect(() => {
    if (!call) {
      setState({ status: "idle" });
      return;
    }

    const controller = new AbortController();
    setState({ status: "loading" });

    call(controller.signal).then((result) => {
      if (controller.signal.aborted) return;
      if (result.ok) {
        setState({ status: "success", data: result.data });
      } else {
        setState({ status: "error", error: result.error });
      }
    });

    return () => {
      controller.abort();
    };
  }, [call]);

  return state;
};

/**
 * Mutation hook that accepts a typed api-client function.
 *
 * Unlike `useApiCall`, the request is triggered imperatively via `mutate()`.
 */
export const useApiMutationCall = <T>(): {
  state: ApiState<T>;
  mutate: (call: () => Promise<ApiResponse<T>>) => Promise<void>;
} => {
  const [state, setState] = useState<ApiState<T>>({ status: "idle" });
  const mountedRef = useRef(true);

  useEffect(() => {
    return () => { mountedRef.current = false; };
  }, []);

  const mutate = useCallback(async (call: () => Promise<ApiResponse<T>>) => {
    setState({ status: "loading" });
    const result = await call();
    if (!mountedRef.current) return;
    if (result.ok) {
      setState({ status: "success", data: result.data });
    } else {
      setState({ status: "error", error: result.error });
    }
  }, []);

  return { state, mutate };
};
