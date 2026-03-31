import { useState, useMemo, useRef, useEffect, useCallback } from "react";
import { useApi } from "../../lib/hooks.ts";
import type { CodeGraph, IndexedFunction } from "@indexion/api-client";
import { LoadingSpinner } from "../../components/shared/loading-spinner.tsx";
import { ErrorPanel } from "../../components/shared/error-panel.tsx";
import { Card, CardHeader, CardTitle, CardDescription } from "../../components/ui/card.tsx";
import type { FolderNode } from "./graph-types.ts";
import { buildTree } from "./graph-data.ts";
import { buildScene } from "./graph-scene.ts";

export const GraphPage = (): React.JSX.Element => {
  const graphState = useApi<CodeGraph>("/graph?format=codegraph");
  const indexState = useApi<ReadonlyArray<IndexedFunction>>("/digest/index");
  const containerRef = useRef<HTMLDivElement>(null);
  const [hovered, setHovered] = useState<FolderNode | null>(null);

  const tree = useMemo(() => {
    if (graphState.status !== "success") return null;
    return buildTree(graphState.data, indexState.status === "success" ? indexState.data : []);
  }, [graphState, indexState]);

  const handleHover = useCallback((n: FolderNode | null) => setHovered(n), []);

  useEffect(() => {
    if (!tree || !containerRef.current) return;
    return buildScene(containerRef.current, tree, handleHover);
  }, [tree, handleHover]);

  const loading = graphState.status !== "success" || indexState.status === "loading";
  const error = graphState.status === "error" ? graphState.error
    : indexState.status === "error" ? indexState.error : null;

  if (loading) return <LoadingSpinner message="Loading graph data..." />;
  if (error) return <ErrorPanel message={error} />;

  return (
    <div className="relative grid h-full grid-rows-[auto_1fr]">
      <div className="flex items-center border-b px-4 py-2">
        <span className="text-sm text-muted-foreground">
          {tree ? `${tree.nodes.size} folders \u00b7 ${tree.edges.length} dependencies` : ""}
        </span>
      </div>
      {hovered && (
        <Card className="pointer-events-none absolute right-4 top-14 z-10 max-w-xs">
          <CardHeader className="p-3">
            <CardTitle className="font-mono text-sm">{hovered.path}</CardTitle>
            <CardDescription className="font-mono">
              {hovered.fileCount} files &middot; {hovered.symbolCount} symbols &middot; {hovered.functionCount} fn
            </CardDescription>
            {hovered.children.length > 0 && (
              <CardDescription>{hovered.children.length} subdirectories</CardDescription>
            )}
          </CardHeader>
        </Card>
      )}
      <div ref={containerRef} className="overflow-hidden" />
    </div>
  );
};
