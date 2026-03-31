/**
 * @file Shared HttpClient instance for the wiki SPA.
 *
 * All pages import this instead of constructing URLs directly.
 * The base URL "/api" matches the dev-server proxy and production setup.
 */

import { createHttpClient } from "@indexion/api-client";

export const client = createHttpClient("/api");
