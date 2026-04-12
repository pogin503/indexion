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
  Branding,
  BrandingColorSet,
  ComparisonStrategy,
  DocGraphFormat,
} from "./types.ts";

export type {
  ExploreRequest,
  DocGraphRequest,
  PlanRequest,
  SpecAlignRequest,
} from "./api.ts";
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
  runSpecAlignDiff,
  runSpecAlignTrace,
  runSpecAlignSuggest,
  runSpecAlignStatus,
  checkHealth,
  fetchConfig,
} from "./api.ts";
