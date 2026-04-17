/**
 * @file React wrapper around the canvas graph viewer.
 *
 * The canvas is driven imperatively through refs. React state is used
 * only for values that affect DOM attributes (canvas size, dpr) or
 * that must trigger a re-render to pick up new props (theme resolution).
 * Selection, hover, filter, and graph positions are managed through
 * refs plus explicit redraw requests — there is no mirrored useState.
 *
 * Environment signals (container size, device pixel ratio, OS color
 * scheme) are subscribed to via useSyncExternalStore to avoid
 * setState-inside-useEffect patterns.
 */

import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useSyncExternalStore,
  type CSSProperties,
} from "react";
import type {
  Camera,
  FilterResult,
  ForceConfig,
  GraphCanvasHandle,
  GraphCanvasProps,
  SelectionState,
  ThemeColors,
  ViewGraph,
  ViewNode,
} from "./types.ts";
import { DEFAULT_CAMERA, DEFAULT_FORCE_CONFIG } from "./types.ts";
import { computeFilter } from "./filter.ts";
import {
  clearSelection,
  createSelectionState,
  enterFocusMode,
  exitFocusMode,
  toggleSelect,
} from "./interaction/selection.ts";
import { createSpatialHash, type SpatialHash } from "./interaction/hit-test.ts";
import { createPointerHandler } from "./interaction/pointer.ts";
import { diffGraph, normalizeGraph } from "./normalize.ts";
import { fitToView } from "./renderer/camera.ts";
import { renderFrame, type CanvasSize } from "./renderer/canvas-renderer.ts";
import { DARK_THEME, LIGHT_THEME } from "./renderer/styles.ts";
import { circularLayout } from "./simulation/layout.ts";
import {
  createSimulation,
  reheat,
  tick,
  type SimulationState,
} from "./simulation/simulation.ts";

const INITIAL_FIT_TICKS = 50;
const DEFAULT_SIZE: CanvasSize = { width: 640, height: 420 };

export const GraphCanvas = forwardRef<GraphCanvasHandle, GraphCanvasProps>(
  function GraphCanvas(props, ref) {
    const containerRef = useRef<HTMLDivElement>(null);
    const canvasRef = useRef<HTMLCanvasElement>(null);

    // --- Imperative canvas state (not React state) ---
    const cameraRef = useRef<Camera>({ ...DEFAULT_CAMERA });
    const simulationRef = useRef<SimulationState | null>(null);
    if (simulationRef.current === null) {
      simulationRef.current = createSimulation();
    }
    const spatialHashRef = useRef<SpatialHash | null>(null);
    if (spatialHashRef.current === null) {
      spatialHashRef.current = createSpatialHash();
    }
    const graphRef = useRef<ViewGraph | null>(null);
    const filterRef = useRef<FilterResult | null>(null);
    const selectionRef = useRef<SelectionState>(createSelectionState());
    const hoverNodeRef = useRef<ViewNode | null>(null);
    const sizeRef = useRef<CanvasSize>(DEFAULT_SIZE);
    const frameRef = useRef<number | null>(null);
    const autoFitDoneRef = useRef(false);
    const simulationTicksRef = useRef(0);

    // --- Environment signals via external stores ---
    const containerSize = useContainerSize(containerRef);
    const dpr = useDevicePixelRatio();
    const theme = useResolvedTheme(props.theme ?? "auto");

    const forceConfig = useMemo<ForceConfig>(
      () => ({ ...DEFAULT_FORCE_CONFIG, ...props.simulationConfig }),
      [props.simulationConfig],
    );

    const size = useMemo<CanvasSize>(
      () => ({
        width: props.width ?? containerSize.width,
        height: props.height ?? containerSize.height,
      }),
      [props.width, props.height, containerSize],
    );
    sizeRef.current = size;

    const renderCurrentFrame = useCallback(() => {
      const canvas = canvasRef.current;
      const graph = graphRef.current;
      const filter = filterRef.current;
      if (!canvas || !graph || !filter) {
        return;
      }
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        return;
      }
      const currentSize = sizeRef.current;
      if (currentSize.width <= 0 || currentSize.height <= 0) {
        return;
      }
      renderFrame({
        ctx,
        graph,
        camera: cameraRef.current,
        filter,
        selection: selectionRef.current,
        styles: theme,
        hoverNode: hoverNodeRef.current,
        canvasSize: currentSize,
        dpr,
      });
    }, [theme, dpr]);

    const requestRedraw = useCallback(() => {
      if (frameRef.current !== null) {
        return;
      }
      frameRef.current = requestAnimationFrame(() => {
        frameRef.current = null;
        const simulation = simulationRef.current;
        const graph = graphRef.current;
        const filter = filterRef.current;
        if (!simulation || !graph || !filter || !spatialHashRef.current) {
          return;
        }

        if (simulation.running) {
          tick(simulation, graph, forceConfig);
          simulationTicksRef.current += 1;
        }
        spatialHashRef.current.rebuild(
          visibleNodesOf(graph, filter.visibleNodes),
        );
        maybeInitialFit({
          autoFitDoneRef,
          simulationTicksRef,
          camera: cameraRef.current,
          graph,
          visibleNodes: filter.visibleNodes,
          size: sizeRef.current,
        });
        renderCurrentFrame();
        if (simulation.running) {
          requestRedraw();
        }
      });
    }, [forceConfig, renderCurrentFrame]);

    const {
      enabledNodeKinds,
      enabledEdgeKinds,
      hideDisconnected,
      searchQuery,
    } = props;
    const recomputeFilter = useCallback(
      (graph: ViewGraph): FilterResult => {
        const next = computeFilter({
          graph,
          enabledNodeKinds,
          enabledEdgeKinds,
          hideDisconnected,
          searchQuery,
        });
        filterRef.current = next;
        return next;
      },
      [enabledNodeKinds, enabledEdgeKinds, hideDisconnected, searchQuery],
    );

    const { onSelectionChange } = props;
    const updateSelection = useCallback(
      (next: SelectionState) => {
        selectionRef.current = next;
        onSelectionChange?.(next.selected);
        requestRedraw();
      },
      [onSelectionChange, requestRedraw],
    );

    // --- Graph input → ViewGraph, with position preservation ---
    useEffect(() => {
      const incoming = normalizeGraph(props.graph);
      const previous = graphRef.current;
      const nextGraph = previous ? diffGraph(previous, incoming) : incoming;
      circularLayout(nextGraph.nodes, nextGraph.edges);
      graphRef.current = nextGraph;
      const filter = recomputeFilter(nextGraph);
      spatialHashRef.current?.rebuild(
        visibleNodesOf(nextGraph, filter.visibleNodes),
      );
      autoFitDoneRef.current = false;
      simulationTicksRef.current = 0;
      if (simulationRef.current) {
        reheat(simulationRef.current, 0.6);
      }
      requestRedraw();
    }, [props.graph, recomputeFilter, requestRedraw]);

    // --- Filter inputs change → recompute, redraw ---
    useEffect(() => {
      const graph = graphRef.current;
      if (!graph) {
        return;
      }
      const filter = recomputeFilter(graph);
      spatialHashRef.current?.rebuild(
        visibleNodesOf(graph, filter.visibleNodes),
      );
      requestRedraw();
    }, [recomputeFilter, requestRedraw]);

    // --- Size/dpr/theme changed → redraw ---
    useEffect(() => {
      requestRedraw();
    }, [size, theme, dpr, requestRedraw]);

    // --- Pointer interaction ---
    const { onNodeClick, onNodeDoubleClick } = props;
    useEffect(() => {
      const canvas = canvasRef.current;
      const spatialHash = spatialHashRef.current;
      if (!canvas || !spatialHash) {
        return;
      }
      const handler = createPointerHandler({
        canvas,
        camera: cameraRef.current,
        spatialHash,
        callbacks: {
          onNodeClick: (node, shift) => {
            onNodeClick?.(node);
            updateSelection(toggleSelect(selectionRef.current, node.id, shift));
          },
          onNodeDoubleClick: (node) => {
            onNodeDoubleClick?.(node);
            const current = selectionRef.current;
            const graph = graphRef.current;
            if (!graph) {
              return;
            }
            const next =
              current.focusCenter === node.id
                ? exitFocusMode(current)
                : enterFocusMode(current, node.id, graph.edges);
            updateSelection(next);
          },
          onBackgroundClick: (shift) => {
            if (shift) {
              return;
            }
            updateSelection(clearSelection(selectionRef.current));
          },
          onBackgroundDoubleClick: () => {
            updateSelection(exitFocusMode(selectionRef.current));
          },
          onDrag: () => {
            requestRedraw();
          },
          onHover: (node) => {
            if (hoverNodeRef.current?.id === node?.id) {
              return;
            }
            hoverNodeRef.current = node;
            requestRedraw();
          },
          onReheat: () => {
            if (simulationRef.current) {
              reheat(simulationRef.current, 0.3);
            }
            requestRedraw();
          },
          requestRedraw,
        },
      });
      handler.attach();
      return () => {
        handler.detach();
      };
    }, [onNodeClick, onNodeDoubleClick, requestRedraw, updateSelection]);

    // --- Cancel pending RAF on unmount ---
    useEffect(() => {
      return () => {
        if (frameRef.current !== null) {
          cancelAnimationFrame(frameRef.current);
          frameRef.current = null;
        }
      };
    }, []);

    useImperativeHandle(
      ref,
      () => ({
        fitToView: (padding: number = 40) => {
          const graph = graphRef.current;
          const filter = filterRef.current;
          if (!graph || !filter) {
            return;
          }
          fitToView({
            camera: cameraRef.current,
            nodes: visibleNodesOf(graph, filter.visibleNodes),
            canvasWidth: sizeRef.current.width,
            canvasHeight: sizeRef.current.height,
            padding,
          });
          requestRedraw();
        },
        selectNode: (id: string) => {
          const graph = graphRef.current;
          if (!graph || !graph.nodeIndex.has(id)) {
            return;
          }
          const current = selectionRef.current;
          updateSelection({
            selected: new Set([id]),
            focusCenter: current.focusCenter,
            focusNeighbors: new Set(current.focusNeighbors),
          });
        },
        clearSelection: () => {
          updateSelection(clearSelection(selectionRef.current));
        },
        resetSimulation: () => {
          const graph = graphRef.current;
          const simulation = simulationRef.current;
          if (!graph || !simulation) {
            return;
          }
          resetNodePositions(graph);
          circularLayout(graph.nodes, graph.edges);
          reheat(simulation, 1);
          simulationTicksRef.current = 0;
          autoFitDoneRef.current = false;
          requestRedraw();
        },
        getNodePosition: (id: string) => {
          const node = graphRef.current?.nodeIndex.get(id);
          if (!node) {
            return null;
          }
          return { x: node.x, y: node.y };
        },
      }),
      [requestRedraw, updateSelection],
    );

    const canvasWidth = Math.max(1, Math.floor(size.width * dpr));
    const canvasHeight = Math.max(1, Math.floor(size.height * dpr));
    const containerStyle = makeContainerStyle(props.width, props.height);

    return (
      <div
        ref={containerRef}
        className={props.className}
        style={containerStyle}
      >
        <canvas
          ref={canvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={{
            display: "block",
            width: `${size.width}px`,
            height: `${size.height}px`,
            touchAction: "none",
          }}
        />
      </div>
    );
  },
);

// --- External-store hooks ---

function useContainerSize(
  ref: React.RefObject<HTMLElement | null>,
): CanvasSize {
  const sizeSnapshotRef = useRef<CanvasSize>(DEFAULT_SIZE);

  const subscribe = useCallback(
    (onChange: () => void) => {
      const element = ref.current;
      if (!element) {
        return () => {};
      }
      const measure = () => {
        const rect = element.getBoundingClientRect();
        const next: CanvasSize = {
          width: Math.max(1, rect.width),
          height: Math.max(1, rect.height),
        };
        const previous = sizeSnapshotRef.current;
        if (previous.width === next.width && previous.height === next.height) {
          return;
        }
        sizeSnapshotRef.current = next;
        onChange();
      };
      measure();
      const observer = new ResizeObserver(measure);
      observer.observe(element);
      window.addEventListener("resize", measure);
      return () => {
        observer.disconnect();
        window.removeEventListener("resize", measure);
      };
    },
    [ref],
  );

  return useSyncExternalStore(
    subscribe,
    () => sizeSnapshotRef.current,
    () => DEFAULT_SIZE,
  );
}

function useDevicePixelRatio(): number {
  const subscribe = useCallback((onChange: () => void) => {
    if (typeof window === "undefined") {
      return () => {};
    }
    let media: MediaQueryList | null = null;
    const attach = () => {
      media = window.matchMedia(`(resolution: ${window.devicePixelRatio}dppx)`);
      media.addEventListener("change", handler);
    };
    const handler = () => {
      if (media) {
        media.removeEventListener("change", handler);
      }
      onChange();
      attach();
    };
    attach();
    return () => {
      if (media) {
        media.removeEventListener("change", handler);
      }
    };
  }, []);

  return useSyncExternalStore(
    subscribe,
    () =>
      typeof window === "undefined"
        ? 1
        : Math.max(1, window.devicePixelRatio || 1),
    () => 1,
  );
}

function usePrefersDark(): boolean {
  const subscribe = useCallback((onChange: () => void) => {
    if (typeof window === "undefined") {
      return () => {};
    }
    const media = window.matchMedia("(prefers-color-scheme: dark)");
    media.addEventListener("change", onChange);
    return () => {
      media.removeEventListener("change", onChange);
    };
  }, []);
  return useSyncExternalStore(
    subscribe,
    () =>
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches,
    () => false,
  );
}

function useResolvedTheme(theme: "dark" | "light" | "auto"): ThemeColors {
  const prefersDark = usePrefersDark();
  if (theme === "dark") {
    return DARK_THEME;
  }
  if (theme === "light") {
    return LIGHT_THEME;
  }
  return prefersDark ? DARK_THEME : LIGHT_THEME;
}

// --- Pure helpers ---

function makeContainerStyle(
  width: number | undefined,
  height: number | undefined,
): CSSProperties {
  return {
    position: "relative",
    width: width ?? "100%",
    height: height ?? "100%",
    minHeight: height ? undefined : 320,
    overflow: "hidden",
  };
}

function visibleNodesOf(
  graph: ViewGraph,
  visibleNodes: ReadonlySet<string>,
): ViewNode[] {
  return graph.nodes.filter((node) => visibleNodes.has(node.id));
}

type InitialFitCtx = {
  readonly autoFitDoneRef: { current: boolean };
  readonly simulationTicksRef: { current: number };
  readonly camera: Camera;
  readonly graph: ViewGraph;
  readonly visibleNodes: ReadonlySet<string>;
  readonly size: CanvasSize;
};

function maybeInitialFit(ctx: InitialFitCtx): void {
  if (ctx.autoFitDoneRef.current) {
    return;
  }
  const nodes = visibleNodesOf(ctx.graph, ctx.visibleNodes);
  if (nodes.length === 0) {
    return;
  }
  // Continuously refit during initial convergence so the graph is
  // always visible — the force simulation may spread nodes beyond
  // the initial layout, and a one-shot fit would leave them off-screen.
  fitToView({
    camera: ctx.camera,
    nodes,
    canvasWidth: ctx.size.width,
    canvasHeight: ctx.size.height,
    padding: 48,
  });
  if (ctx.simulationTicksRef.current >= INITIAL_FIT_TICKS) {
    ctx.autoFitDoneRef.current = true;
  }
}

function resetNodePositions(graph: ViewGraph): void {
  for (const node of graph.nodes) {
    node.x = 0;
    node.y = 0;
    node.vx = 0;
    node.vy = 0;
    node.pinned = false;
  }
}
