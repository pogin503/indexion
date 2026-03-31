/**
 * @file Custom hooks for API data fetching.
 */

import { useState, useEffect, useCallback } from "react";
import { apiGet, apiPost, type ApiResponse } from "@indexion/api-client";

export type ApiState<T> =
  | { readonly status: "idle" }
  | { readonly status: "loading" }
  | { readonly status: "success"; readonly data: T }
  | { readonly status: "error"; readonly error: string };

export const useApi = <T>(url: string | null): ApiState<T> => {
  const [state, setState] = useState<ApiState<T>>({ status: "idle" });

  useEffect(() => {
    if (!url) {
      setState({ status: "idle" });
      return;
    }

    const controller = new AbortController();
    setState({ status: "loading" });

    apiGet<T>(url, controller.signal).then((result) => {
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
  }, [url]);

  return state;
};

export const useApiMutation = <TInput, TOutput>(): {
  state: ApiState<TOutput>;
  mutate: (url: string, body: TInput) => Promise<void>;
} => {
  const [state, setState] = useState<ApiState<TOutput>>({ status: "idle" });

  const mutate = useCallback(async (url: string, body: TInput) => {
    setState({ status: "loading" });
    const result: ApiResponse<TOutput> = await apiPost<TOutput>(url, body);
    if (result.ok) {
      setState({ status: "success", data: result.data });
    } else {
      setState({ status: "error", error: result.error });
    }
  }, []);

  return { state, mutate };
};
