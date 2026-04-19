import { useState, useCallback } from "react";
import { useApiCall } from "../../lib/hooks.ts";
import { client } from "../../lib/client.ts";
import { fetchGraph } from "@indexion/api-client";
import { GraphCanvas, type ViewNode } from "@indexion/graph-canvas";
import { LoadingSpinner } from "../../components/shared/loading-spinner.tsx";
import { ErrorPanel } from "../../components/shared/error-panel.tsx";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
} from "../../components/ui/card.tsx";
import { useDict } from "../../i18n/index.ts";

export const GraphPage = (): React.JSX.Element => {
  const d = useDict();
  const graphState = useApiCall((signal) => fetchGraph(client, signal));
  const [focused, setFocused] = useState<ViewNode | null>(null);

  const handleNodeClick = useCallback((node: ViewNode) => setFocused(node), []);

  if (graphState.status === "error") {
    return <ErrorPanel message={graphState.error} />;
  }
  if (graphState.status !== "success") {
    return <LoadingSpinner message={d.loading_graph} />;
  }

  const graph = graphState.data;
  const nodeCount =
    Object.keys(graph.modules).length + Object.keys(graph.symbols).length;
  const edgeCount = graph.edges.length;

  return (
    <div className="relative grid h-full grid-rows-[auto_1fr]">
      <div className="flex items-center border-b px-4 py-2">
        <span className="text-sm text-muted-foreground">
          {d.graph_stats(nodeCount, edgeCount)}
        </span>
      </div>
      {focused && (
        <Card className="pointer-events-none absolute right-4 top-14 z-10 max-w-xs">
          <CardHeader className="p-3">
            <CardTitle className="font-mono text-sm">{focused.label}</CardTitle>
            <CardDescription className="font-mono">{focused.kind}</CardDescription>
            {focused.file && (
              <CardDescription className="font-mono text-xs">
                {focused.file}
              </CardDescription>
            )}
          </CardHeader>
        </Card>
      )}
      <GraphCanvas
        graph={graph}
        clustering="directory"
        layoutStrategy="hierarchy"
        onNodeClick={handleNodeClick}
      />
    </div>
  );
};
