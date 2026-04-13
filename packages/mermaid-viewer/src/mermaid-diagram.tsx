/**
 * @file Mermaid diagram renderer with pinch-to-zoom and pan support.
 *
 * Lazy-loads mermaid, renders to SVG. SVG keeps intrinsic viewBox dimensions.
 * TransformWrapper scales it to fit container width via setTransform().
 * Container height is computed from SVG aspect ratio and measured width.
 * The diagram stays hidden until the initial fit completes to avoid flash.
 */

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
} from "react";
import {
  TransformWrapper,
  TransformComponent,
  type ReactZoomPanPinchRef,
} from "react-zoom-pan-pinch";
import { Fullscreen, Maximize2, X, ZoomIn, ZoomOut } from "lucide-react";

// ── Types ──────────────────────────────────────────────────────────

type Props = {
  readonly code: string;
  readonly className?: string;
};

type SvgData = {
  html: string;
  w: number;
  h: number;
};

// ── SVG parsing ────────────────────────────────────────────────────

const DEFAULT_SIZE = { w: 800, h: 600 };

/** Parse mermaid SVG: ensure viewBox, set intrinsic w/h, strip inline style. */
function parseMermaidSvg(raw: string): SvgData {
  const doc = new DOMParser().parseFromString(raw, "image/svg+xml");
  const el = doc.querySelector("svg");
  if (!el) {
    return { html: raw, ...DEFAULT_SIZE };
  }

  let { w, h } = extractViewBoxSize(el);
  if (w <= 0 || h <= 0) {
    w = parseFloat(el.getAttribute("width") ?? String(DEFAULT_SIZE.w));
    h = parseFloat(el.getAttribute("height") ?? String(DEFAULT_SIZE.h));
    el.setAttribute("viewBox", `0 0 ${w} ${h}`);
  }

  el.setAttribute("width", String(w));
  el.setAttribute("height", String(h));
  el.removeAttribute("style"); // mermaid injects max-width

  return { html: el.outerHTML, w, h };
}

function extractViewBoxSize(el: SVGSVGElement): { w: number; h: number } {
  const vb = el.getAttribute("viewBox");
  if (!vb) {
    return { w: 0, h: 0 };
  }
  const parts = vb.split(/[\s,]+/).map(Number);
  if (parts.length === 4 && parts[2]! > 0 && parts[3]! > 0) {
    return { w: parts[2]!, h: parts[3]! };
  }
  return { w: 0, h: 0 };
}

// ── Mermaid render store ───────────────────────────────────────────

type MermaidEntry =
  | { readonly state: "resolved"; readonly svg: SvgData }
  | { readonly state: "error"; readonly message: string };

const mermaidCache = new Map<string, MermaidEntry>();
const mermaidInflight = new Set<string>();
const mermaidListeners = new Set<() => void>();
let mermaidVersion = 0;

function mermaidSubscribe(cb: () => void): () => void {
  mermaidListeners.add(cb);
  return () => mermaidListeners.delete(cb);
}

function mermaidGetSnapshot(): number {
  return mermaidVersion;
}

function mermaidNotify(): void {
  mermaidVersion++;
  for (const cb of mermaidListeners) {
    cb();
  }
}

function ensureMermaidRender(code: string): void {
  if (mermaidCache.has(code) || mermaidInflight.has(code)) {
    return;
  }
  mermaidInflight.add(code);
  renderMermaid(code);
}

async function renderMermaid(code: string): Promise<void> {
  try {
    const { default: mermaid } = await import("mermaid");
    mermaid.initialize({ startOnLoad: false, theme: "dark" });
    const { svg: raw } = await mermaid.render(
      `mermaid-${Math.random().toString(36).slice(2)}`,
      code,
    );
    mermaidCache.set(code, { state: "resolved", svg: parseMermaidSvg(raw) });
  } catch (err: unknown) {
    console.error("[mermaid-viewer] Render failed:", err);
    mermaidCache.set(code, { state: "error", message: String(err) });
  }
  mermaidInflight.delete(code);
  mermaidNotify();
}

// ── Hooks ──────────────────────────────────────────────────────────

/** Lazy-load mermaid, render code to normalized SVG data. */
function useMermaidSvg(code: string) {
  const version = useSyncExternalStore(
    mermaidSubscribe,
    mermaidGetSnapshot,
    mermaidGetSnapshot,
  );

  useEffect(() => {
    if (code.trim()) {
      ensureMermaidRender(code);
    }
  }, [code]);

  return useMemo(() => {
    void version;
    if (!code.trim()) {
      return { svg: null, error: null };
    }
    const entry = mermaidCache.get(code);
    if (!entry) {
      return { svg: null, error: null };
    }
    switch (entry.state) {
      case "resolved":
        return { svg: entry.svg, error: null };
      case "error":
        return { svg: null, error: entry.message };
    }
  }, [code, version]);
}

const MIN_HEIGHT = 120;
const MAX_VH = 0.8;

/**
 * Measure container width, compute display height from SVG aspect ratio,
 * and call setTransform to fit the SVG to container width.
 * Tracks `ready` state — false until the first successful fit.
 */
/**
 * Fit-to-width state tracked via a monotonic version counter.
 * `svgVersion` increments when svg changes (not yet fitted).
 * `fitVersion` increments when fitToWidth completes.
 * `ready` = they match (current svg has been fitted).
 */
function useFitToWidth(svg: SvgData | null) {
  const outerRef = useRef<HTMLDivElement>(null);
  const transformRef = useRef<ReactZoomPanPinchRef>(null);
  const [displayHeight, setDisplayHeight] = useState(300);
  const prevWidthRef = useRef(0);

  // Version tracking: ready when fitVersion catches up to svgVersion
  const svgVersionRef = useRef(0);
  const [fitVersion, setFitVersion] = useState(0);

  // Increment svgVersion when svg changes
  const currentSvgVersion = useMemo(() => {
    svgVersionRef.current++;
    return svgVersionRef.current;
  }, [svg]);

  const ready = fitVersion >= currentSvgVersion;

  const fitToWidth = useCallback(() => {
    const el = outerRef.current;
    if (!el || !svg) {
      return;
    }
    const cw = el.clientWidth;
    if (cw <= 0) {
      return;
    }

    const scale = cw / svg.w;
    const maxH = window.innerHeight * MAX_VH;
    const containerH = Math.max(Math.min(svg.h * scale, maxH), MIN_HEIGHT);
    setDisplayHeight(containerH);

    // setDisplayHeight triggers re-render → need to wait for DOM update.
    // Double-rAF: first waits for React commit, second for browser layout.
    const targetVersion = svgVersionRef.current;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        const ref = transformRef.current;
        if (!ref) {
          return;
        }
        const scaledH = svg.h * scale;
        const y = scaledH < containerH ? (containerH - scaledH) / 2 : 0;
        ref.setTransform(0, y, scale, 0);
        setFitVersion(targetVersion);
      });
    });
  }, [svg]);

  // Observe container width changes (width-only to avoid height→resize loop)
  useEffect(() => {
    const el = outerRef.current;
    if (!el || !svg) {
      return;
    }
    const ro = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const w = entry.contentRect.width;
        if (Math.abs(w - prevWidthRef.current) > 1) {
          prevWidthRef.current = w;
          fitToWidth();
        }
      }
    });
    ro.observe(el);
    fitToWidth();
    return () => ro.disconnect();
  }, [svg, fitToWidth]);

  return { outerRef, transformRef, displayHeight, fitToWidth, ready };
}

// ── Components ─────────────────────────────────────────────────────

export const MermaidDiagram = ({
  code,
  className,
}: Props): React.JSX.Element => {
  const { svg, error } = useMermaidSvg(code);
  const [expanded, setExpanded] = useState(false);
  const { outerRef, transformRef, displayHeight, fitToWidth, ready } =
    useFitToWidth(svg);

  if (error) {
    return (
      <pre className="overflow-auto rounded border border-destructive/30 bg-destructive/10 p-3 text-xs text-destructive">
        {error}
      </pre>
    );
  }

  if (!svg) {
    return (
      <div
        className={`flex h-32 items-center justify-center rounded border border-border/50 text-sm text-muted-foreground ${className ?? ""}`}
      >
        Loading diagram…
      </div>
    );
  }

  return (
    <>
      {/* Inline preview — hidden until initial fit completes */}
      <div
        ref={outerRef}
        className={`relative overflow-hidden rounded border border-border/50 ${ready ? "visible" : "invisible"} ${className ?? ""}`}
        style={{ height: displayHeight }}
      >
        <TransformWrapper
          ref={transformRef}
          initialScale={1}
          minScale={0.1}
          maxScale={8}
          wheel={{ step: 0.1 }}
          panning={{ velocityDisabled: true }}
          limitToBounds={false}
        >
          {({ zoomIn, zoomOut }) => (
            <>
              <TransformComponent
                wrapperStyle={{ width: "100%", height: "100%" }}
              >
                <div dangerouslySetInnerHTML={{ __html: svg.html }} />
              </TransformComponent>
              <Toolbar position="right-1.5 top-1.5" size="size-3">
                <ToolButton onClick={() => zoomIn()} label="Zoom in">
                  <ZoomIn />
                </ToolButton>
                <ToolButton onClick={() => zoomOut()} label="Zoom out">
                  <ZoomOut />
                </ToolButton>
                <ToolButton onClick={fitToWidth} label="Fit width">
                  <Maximize2 />
                </ToolButton>
                <ToolButton
                  onClick={() => setExpanded(true)}
                  label="Full screen"
                >
                  <Fullscreen />
                </ToolButton>
              </Toolbar>
            </>
          )}
        </TransformWrapper>
      </div>

      {/* Full-screen viewer */}
      {expanded && (
        <FullScreenViewer
          svgHtml={svg.html}
          onClose={() => setExpanded(false)}
        />
      )}
    </>
  );
};

// ── Full-screen viewer ─────────────────────────────────────────────

const FullScreenViewer = ({
  svgHtml,
  onClose,
}: {
  readonly svgHtml: string;
  readonly onClose: () => void;
}): React.JSX.Element => (
  <div className="fixed inset-0 z-50 bg-background">
    <TransformWrapper
      initialScale={1}
      minScale={0.3}
      maxScale={8}
      centerOnInit
      wheel={{ step: 0.1 }}
      panning={{ velocityDisabled: true }}
    >
      {({ zoomIn, zoomOut, resetTransform, zoomToElement }) => (
        <>
          <TransformComponent wrapperStyle={{ width: "100%", height: "100%" }}>
            <div
              ref={(el) => {
                if (el) {
                  requestAnimationFrame(() =>
                    zoomToElement(el, undefined, 100),
                  );
                }
              }}
              dangerouslySetInnerHTML={{ __html: svgHtml }}
            />
          </TransformComponent>
          <Toolbar position="right-3 top-3" size="size-3.5">
            <ToolButton onClick={() => zoomIn()} label="Zoom in">
              <ZoomIn />
            </ToolButton>
            <ToolButton onClick={() => zoomOut()} label="Zoom out">
              <ZoomOut />
            </ToolButton>
            <ToolButton onClick={() => resetTransform()} label="Reset">
              <Maximize2 />
            </ToolButton>
            <ToolButton onClick={onClose} label="Close">
              <X />
            </ToolButton>
          </Toolbar>
        </>
      )}
    </TransformWrapper>
  </div>
);

// ── Shared toolbar UI ──────────────────────────────────────────────

const Toolbar = ({
  position,
  size,
  children,
}: {
  readonly position: string;
  readonly size: string;
  readonly children: React.ReactNode;
}): React.JSX.Element => (
  <div className={`absolute ${position} z-10 flex gap-1 [&_svg]:${size}`}>
    {children}
  </div>
);

const ToolButton = ({
  onClick,
  label,
  children,
}: {
  readonly onClick: () => void;
  readonly label: string;
  readonly children: React.ReactNode;
}): React.JSX.Element => (
  <button
    type="button"
    onPointerDown={(e) => e.stopPropagation()}
    onClick={(e) => {
      e.stopPropagation();
      onClick();
    }}
    aria-label={label}
    className="pointer-events-auto rounded bg-background/80 p-1 text-muted-foreground backdrop-blur-sm transition-colors hover:bg-accent hover:text-foreground"
  >
    {children}
  </button>
);
