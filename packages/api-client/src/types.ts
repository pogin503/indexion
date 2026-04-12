/**
 * @file API response types — single source of truth for all consumers.
 *
 * These types describe the JSON shapes returned by `indexion serve`.
 * Both deepwiki (browser) and vscode-plugin (Node) import from here.
 */

// --- Response envelope ---

/** Discriminated union for all API responses. */
export type ApiResponse<T> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: string };

// --- Graph ---

export type CodeGraph = {
  readonly modules: Record<string, { readonly file?: string }>;
  readonly symbols: Record<string, SymbolNode>;
  readonly edges: ReadonlyArray<GraphEdge>;
};

export type SymbolNode = {
  readonly name: string;
  readonly kind: string;
  readonly ns: string;
  readonly module: string;
  readonly doc?: string;
};

export type GraphEdge = {
  readonly kind: string;
  readonly from: string;
  readonly to: string;
};

// --- Digest ---

export type DigestMatch = {
  readonly name: string;
  readonly file: string;
  readonly score: number;
  readonly summary: string;
};

export type IndexedFunction = {
  readonly id: string;
  readonly name: string;
  readonly module: string;
  readonly kind: string;
  readonly doc: string | null;
  readonly summary: string | null;
  readonly keywords: ReadonlyArray<string>;
  readonly callers: ReadonlyArray<string>;
  readonly callees: ReadonlyArray<string>;
  readonly depth: number;
};

// --- Wiki ---

export type WikiPage = {
  readonly id: string;
  readonly title: string;
  readonly content: string;
  readonly sources: ReadonlyArray<WikiSourceRef>;
  readonly headings: ReadonlyArray<WikiHeading>;
  readonly children: ReadonlyArray<string>;
  readonly parent: string | null;
};

export type WikiSourceRef = {
  readonly file: string;
  readonly lines: readonly [number, number];
};

export type WikiHeading = {
  readonly level: number;
  readonly text: string;
  readonly anchor: string;
};

export type WikiNavItem = {
  readonly id: string;
  readonly title: string;
  readonly children: ReadonlyArray<WikiNavItem>;
};

export type WikiNav = {
  readonly pages: ReadonlyArray<WikiNavItem>;
};

// --- Explore ---

export type SimilarityPair = {
  readonly file1: string;
  readonly file2: string;
  readonly similarity: number;
};

export type ExploreResult = {
  readonly files: ReadonlyArray<string>;
  readonly pairs: ReadonlyArray<SimilarityPair>;
};

// --- KGF ---

export type KgfSpecInfo = {
  readonly name: string;
  readonly category: string;
  readonly sources: ReadonlyArray<string>;
};

export type KgfToken = {
  readonly kind: string;
  readonly text: string;
  readonly line: number;
  readonly col: number;
};

export type KgfEdge = {
  readonly from: string;
  readonly to: string;
  readonly kind: string;
};

// --- Config ---

export type BrandingColorSet = {
  readonly background: string | null;
  readonly foreground: string | null;
  readonly primary: string | null;
  readonly accent: string | null;
};

export type Branding = {
  readonly title: string | null;
  readonly defaultColorScheme: string | null;
  readonly locale: string | null;
  readonly logoUrl: string | null;
  readonly logoAlt: string | null;
  readonly colors: {
    readonly dark: BrandingColorSet;
    readonly light: BrandingColorSet;
  };
};

export type ServerConfig = {
  readonly workspaceDir: string;
  readonly specsDir: string;
  readonly indexDir: string;
  readonly configDir: string | null;
  readonly dataDir: string | null;
  readonly cacheDir: string | null;
  readonly branding: Branding;
};

// --- Enums (string literal unions for API parameters) ---

export type ComparisonStrategy = "tfidf" | "ncd" | "hybrid" | "apted" | "tsed";

export type DocGraphFormat =
  | "mermaid"
  | "json"
  | "dot"
  | "d2"
  | "text"
  | "codegraph";
