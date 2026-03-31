/**
 * @file Wiki-specific data fetching hooks.
 */

import { useMemo } from "react";
import { useApiCall } from "../../../lib/hooks.ts";
import { client } from "../../../lib/client.ts";
import { fetchWikiNav, fetchWikiPage, type ApiResponse, type WikiPage } from "@indexion/api-client";

export const useWikiNav = () =>
  useApiCall((signal) => fetchWikiNav(client, signal));

export const useWikiPage = (pageId: string | undefined) => {
  const call = useMemo(
    (): ((signal: AbortSignal) => Promise<ApiResponse<WikiPage>>) | null =>
      pageId
        ? (signal: AbortSignal) => fetchWikiPage(client, pageId, signal)
        : null,
    [pageId],
  );
  return useApiCall(call);
};
