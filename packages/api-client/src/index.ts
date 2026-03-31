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
  ServerConfig,
  ComparisonStrategy,
  DocGraphFormat,
} from "./types.ts";

export type { ExploreRequest, DocGraphRequest, PlanRequest } from "./api.ts";
export {
  fetchGraph,
  queryDigest,
  fetchDigestIndex,
  fetchDigestStats,
  rebuildDigest,
  fetchWikiNav,
  fetchWikiPage,
  searchWiki,
  runExplore,
  fetchKgfList,
  tokenizeFile,
  extractEdges,
  generateDocGraph,
  runPlanRefactor,
  runPlanDocumentation,
  runPlanReconcile,
  runPlanSolid,
  runPlanUnwrap,
  runPlanReadme,
  checkHealth,
  fetchConfig,
} from "./api.ts";
