export type FileInfo = {
  path: string;
  name: string;
  symbols: SymbolInfo[];
};

export type SymbolInfo = {
  id: string;
  name: string;
  kind: string;
};

export type FolderNode = {
  path: string;
  name: string;
  depth: number;
  children: string[];
  isLeaf: boolean;
  fileCount: number;
  symbolCount: number;
  functionCount: number;
  files: FileInfo[];
};

export type DepEdge = { from: string; to: string };

export type GraphTree = {
  nodes: Map<string, FolderNode>;
  edges: DepEdge[];
  roots: string[];
};
