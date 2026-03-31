/**
 * @file API response types for codebase search.
 */

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
