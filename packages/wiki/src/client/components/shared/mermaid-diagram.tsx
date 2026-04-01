/**
 * @file Mermaid diagram renderer with pinch-to-zoom and pan support.
 *
 * Lazy-loads mermaid, renders to SVG. SVG keeps intrinsic viewBox dimensions.
 * TransformWrapper scales it to fit container width via setTransform().
 * Container height is computed from SVG aspect ratio and measured width.
 */

import { useCallback, useEffect, useRef, useState } from "react";
import {
  TransformWrapper,
  TransformComponent,
  type ReactZoomPanPinchRef,
} from "react-zoom-pan-pinch";
import { Maximize2, X, ZoomIn, ZoomOut } from "lucide-react";

type Props = {
  readonly code: string;
  readonly className?: string;
};

type SvgData = {
  html: string;
  w: number;
  h: number;
};

export const MermaidDiagram = ({
  code,
  className,
}: Props): React.JSX.Element => {
  const [error, setError] = useState<string | null>(null);
  const [svg, setSvg] = useState<SvgData | null>(null);
  const [expanded, setExpanded] = useState(false);
  const [displayHeight, setDisplayHeight] = useState(300);
  const outerRef = useRef<HTMLDivElement>(null);
  const transformRef = useRef<ReactZoomPanPinchRef>(null);

  const parseSvg = useCallback((raw: string): SvgData => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(raw, "image/svg+xml");
    const el = doc.querySelector("svg");
    if (!el) return { html: raw, w: 800, h: 600 };

    let w = 0, h = 0;
    const vb = el.getAttribute("viewBox");
    if (vb) {
      const p = vb.split(/[\s,]+/).map(Number);
      if (p.length === 4) { w = p[2]!; h = p[3]!; }
    }
    if (w <= 0 || h <= 0) {
      w = parseFloat(el.getAttribute("width") ?? "800");
      h = parseFloat(el.getAttribute("height") ?? "600");
      el.setAttribute("viewBox", `0 0 ${w} ${h}`);
    }

    el.setAttribute("width", String(w));
    el.setAttribute("height", String(h));
    el.removeAttribute("style");

    return { html: el.outerHTML, w, h };
  }, []);

  useEffect(() => {
    if (!code.trim()) return;
    let cancelled = false;
    setError(null);

    import("mermaid").then(({ default: mermaid }) => {
      if (cancelled) return;
      mermaid.initialize({ startOnLoad: false, theme: "dark" });
      const id = `mermaid-${Math.random().toString(36).slice(2)}`;
      mermaid
        .render(id, code)
        .then(({ svg: raw }) => { if (!cancelled) setSvg(parseSvg(raw)); })
        .catch((err) => { if (!cancelled) setError(String(err)); });
    });

    return () => { cancelled = true; };
  }, [code, parseSvg]);

  // Compute height and apply scale whenever container width or svg changes
  const fitToWidth = useCallback(() => {
    const el = outerRef.current;
    const ref = transformRef.current;
    if (!el || !svg) return;
    const cw = el.clientWidth;
    if (cw <= 0) return;

    const scale = cw / svg.w;
    const maxVh = window.innerHeight * 0.8;
    const h = Math.max(Math.min(svg.h * scale, maxVh), 120);
    setDisplayHeight(h);

    if (ref) {
      // Apply after React renders the new height
      requestAnimationFrame(() => ref.setTransform(0, 0, scale));
    }
  }, [svg]);

  // Observe container width changes (track width only to avoid height→resize loop)
  const prevWidthRef = useRef(0);
  useEffect(() => {
    const el = outerRef.current;
    if (!el || !svg) return;
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

  if (error) {
    return (
      <pre className="overflow-auto rounded border border-destructive/30 bg-destructive/10 p-3 text-xs text-destructive">
        {error}
      </pre>
    );
  }

  if (!svg) {
    return (
      <div className={`flex h-32 items-center justify-center rounded border border-border/50 text-sm text-muted-foreground ${className ?? ""}`}>
        Loading diagram…
      </div>
    );
  }

  return (
    <>
      <div
        ref={outerRef}
        className={`relative overflow-hidden rounded border border-border/50 ${className ?? ""}`}
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
              <div className="absolute right-2 top-2 z-10 flex gap-1">
                <ToolButton onClick={() => zoomIn()} label="Zoom in">
                  <ZoomIn className="size-3.5" />
                </ToolButton>
                <ToolButton onClick={() => zoomOut()} label="Zoom out">
                  <ZoomOut className="size-3.5" />
                </ToolButton>
                <ToolButton onClick={fitToWidth} label="Fit width">
                  <Maximize2 className="size-3.5" />
                </ToolButton>
                <ToolButton onClick={() => setExpanded(true)} label="Full screen">
                  <Maximize2 className="size-3.5" />
                </ToolButton>
              </div>
            </>
          )}
        </TransformWrapper>
      </div>

      {expanded && (
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
                <TransformComponent
                  wrapperStyle={{ width: "100%", height: "100%" }}
                >
                  <div
                    ref={(el) => {
                      if (el) {
                        requestAnimationFrame(() => zoomToElement(el, undefined, 100));
                      }
                    }}
                    dangerouslySetInnerHTML={{ __html: svg.html }}
                  />
                </TransformComponent>
                <div className="absolute right-3 top-3 z-10 flex gap-1">
                  <ToolButton onClick={() => zoomIn()} label="Zoom in">
                    <ZoomIn className="size-4" />
                  </ToolButton>
                  <ToolButton onClick={() => zoomOut()} label="Zoom out">
                    <ZoomOut className="size-4" />
                  </ToolButton>
                  <ToolButton onClick={() => resetTransform()} label="Reset">
                    <Maximize2 className="size-4" />
                  </ToolButton>
                  <ToolButton onClick={() => setExpanded(false)} label="Close">
                    <X className="size-4" />
                  </ToolButton>
                </div>
              </>
            )}
          </TransformWrapper>
        </div>
      )}
    </>
  );
};

type ToolButtonProps = {
  readonly onClick: () => void;
  readonly label: string;
  readonly children: React.ReactNode;
};

const ToolButton = ({
  onClick,
  label,
  children,
}: ToolButtonProps): React.JSX.Element => (
  <button
    type="button"
    onPointerDown={(e) => e.stopPropagation()}
    onClick={(e) => {
      e.stopPropagation();
      onClick();
    }}
    aria-label={label}
    className="pointer-events-auto rounded bg-background/80 p-1.5 text-muted-foreground backdrop-blur-sm transition-colors hover:bg-accent hover:text-foreground"
  >
    {children}
  </button>
);
