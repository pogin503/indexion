/**
 * @file Barrel export for @indexion/api-client.
 */

export type { HttpClient } from "./client.ts";
export { createHttpClient, apiGet, apiPost } from "./client.ts";

export type {
  ApiResponse,
  CodeGraph,
  SymbolNode,
  GraphEdge,
  DigestMatch,
  IndexedFunction,
  WikiPage,
  WikiSourceRef,
  WikiHeading,
  WikiNavItem,
  WikiNav,
  SimilarityPair,
  ExploreResult,
  KgfSpecInfo,
  KgfToken,
  KgfEdge,
} from "./types.ts";
