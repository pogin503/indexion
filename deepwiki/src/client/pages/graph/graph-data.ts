import type { CodeGraph, IndexedFunction } from "../../lib/types.ts";
import type { FileInfo, SymbolInfo, FolderNode, DepEdge, GraphTree } from "./graph-types.ts";

const packageOf = (moduleId: string): string => {
  const idx = moduleId.lastIndexOf("/");
  return idx > 0 ? moduleId.slice(0, idx) : moduleId;
};

const detectProjectPrefix = (
  edges: ReadonlyArray<{ kind: string; from: string; to: string }>,
  folderSet: Set<string>,
): string => {
  const candidates = new Map<string, number>();
  for (const e of edges) {
    if (e.kind !== "module_depends_on" || !e.to.startsWith("pkg:")) continue;
    const rest = e.to.slice(4);
    const parts = rest.split("/");
    for (let i = 1; i <= Math.min(parts.length - 1, 3); i++) {
      const prefix = parts.slice(0, i).join("/") + "/";
      const localPath = rest.slice(prefix.length);
      if (folderSet.has(localPath)) candidates.set(prefix, (candidates.get(prefix) ?? 0) + 1);
    }
  }
  let best = ""; let bc = 0;
  for (const [p, c] of candidates) { if (c > bc) { best = p; bc = c; } }
  return best;
};

export const buildTree = (graph: CodeGraph, indexFns: ReadonlyArray<IndexedFunction>): GraphTree => {
  const localModules = Object.keys(graph.modules).filter(
    (m) => !m.startsWith("npm:") && !m.startsWith("pkg:") && !m.startsWith("url:"),
  );
  const leafDirs = new Set<string>();
  for (const m of localModules) { const p = packageOf(m); if (p && p !== m) leafDirs.add(p); }
  const allDirs = new Set<string>();
  for (const d of leafDirs) {
    const parts = d.split("/");
    for (let i = 1; i <= parts.length; i++) allDirs.add(parts.slice(0, i).join("/"));
  }
  const fileSymbols = new Map<string, SymbolInfo[]>();
  for (const [sid, sym] of Object.entries(graph.symbols)) {
    const arr = fileSymbols.get(sym.module) ?? [];
    arr.push({ id: sid, name: sym.name, kind: sym.kind });
    fileSymbols.set(sym.module, arr);
  }
  const pkgFiles = new Map<string, FileInfo[]>();
  for (const m of localModules) {
    const p = packageOf(m);
    const arr = pkgFiles.get(p) ?? [];
    const fname = m.split("/").pop() ?? m;
    arr.push({ path: m, name: fname, symbols: fileSymbols.get(m) ?? [] });
    pkgFiles.set(p, arr);
  }
  const symCount = new Map<string, number>();
  for (const [, sym] of Object.entries(graph.symbols)) {
    const p = packageOf(sym.module); symCount.set(p, (symCount.get(p) ?? 0) + 1);
  }
  const fnCount = new Map<string, number>();
  for (const fn of indexFns) { const p = packageOf(fn.module); fnCount.set(p, (fnCount.get(p) ?? 0) + 1); }
  const fileCnt = new Map<string, number>();
  for (const m of localModules) { const p = packageOf(m); fileCnt.set(p, (fileCnt.get(p) ?? 0) + 1); }
  const nodes = new Map<string, FolderNode>();
  for (const dir of allDirs) {
    const parts = dir.split("/");
    const hasChildDirs = [...allDirs].some((d) => d !== dir && d.startsWith(dir + "/"));
    nodes.set(dir, {
      path: dir, name: parts[parts.length - 1], depth: parts.length - 1,
      children: [], isLeaf: !hasChildDirs,
      fileCount: fileCnt.get(dir) ?? 0, symbolCount: symCount.get(dir) ?? 0,
      functionCount: fnCount.get(dir) ?? 0,
      files: pkgFiles.get(dir) ?? [],
    });
  }
  for (const [path] of nodes) {
    const parts = path.split("/");
    if (parts.length > 1) nodes.get(parts.slice(0, -1).join("/"))?.children.push(path);
  }
  for (const [, n] of nodes) n.children.sort();
  const projectPrefix = detectProjectPrefix(graph.edges, leafDirs);
  const edges: DepEdge[] = []; const edgeSet = new Set<string>();
  for (const e of graph.edges) {
    if (e.kind !== "module_depends_on") continue;
    const fromDir = packageOf(e.from);
    if (!leafDirs.has(fromDir)) continue;
    let toDir: string | null = null;
    if (e.to.startsWith("pkg:" + projectPrefix)) toDir = e.to.slice(("pkg:" + projectPrefix).length);
    else if (!e.to.startsWith("pkg:") && !e.to.startsWith("npm:") && !e.to.startsWith("url:")) toDir = packageOf(e.to);
    if (toDir && leafDirs.has(toDir) && fromDir !== toDir) {
      const key = `${fromDir}\0${toDir}`;
      if (!edgeSet.has(key)) { edgeSet.add(key); edges.push({ from: fromDir, to: toDir }); }
    }
  }
  const roots = [...nodes.keys()].filter((p) => {
    const parts = p.split("/");
    return parts.length === 1 || !nodes.has(parts.slice(0, -1).join("/"));
  });
  return { nodes, edges, roots: roots.sort() };
};
