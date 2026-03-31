/**
 * @file Wiki-specific data fetching hooks.
 */

import { useApi } from "../../../lib/hooks.ts";
import type { WikiNav, WikiPage } from "@indexion/api-client";

export const useWikiNav = () => useApi<WikiNav>("/wiki/nav");

export const useWikiPage = (pageId: string | undefined) =>
  useApi<WikiPage>(pageId ? `/wiki/pages/${pageId}` : null);
