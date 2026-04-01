/**
 * @file Mermaid diagram renderer with pinch-to-zoom and pan support.
 *
 * Lazy-loads mermaid, renders to SVG, then wraps in react-zoom-pan-pinch
 * so users can interact on both desktop and mobile.
 * Tap opens a full-screen viewer with the same pan/zoom controls.
 */

import { useEffect, useState } from "react";
import {
  TransformWrapper,
  TransformComponent,
} from "react-zoom-pan-pinch";
import { Maximize2, X, ZoomIn, ZoomOut } from "lucide-react";

type Props = {
  readonly code: string;
  readonly className?: string;
};

export const MermaidDiagram = ({
  code,
  className,
}: Props): React.JSX.Element => {
  const [error, setError] = useState<string | null>(null);
  const [svgHtml, setSvgHtml] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    if (!code.trim()) {
      return;
    }
    let cancelled = false;
    setError(null);

    import("mermaid").then(({ default: mermaid }) => {
      if (cancelled) {
        return;
      }
      mermaid.initialize({ startOnLoad: false, theme: "dark" });
      const id = `mermaid-${Math.random().toString(36).slice(2)}`;
      mermaid
        .render(id, code)
        .then(({ svg }) => {
          if (!cancelled) {
            setSvgHtml(svg);
          }
        })
        .catch((err) => {
          if (!cancelled) {
            setError(String(err));
          }
        });
    });

    return () => {
      cancelled = true;
    };
  }, [code]);

  if (error) {
    return (
      <pre className="overflow-auto rounded border border-destructive/30 bg-destructive/10 p-3 text-xs text-destructive">
        {error}
      </pre>
    );
  }

  if (!svgHtml) {
    return (
      <div className={`flex h-32 items-center justify-center rounded border border-border/50 text-sm text-muted-foreground ${className ?? ""}`}>
        Loading diagram…
      </div>
    );
  }

  return (
    <>
      {/* Inline preview with pan/zoom */}
      <div className={`relative rounded border border-border/50 ${className ?? ""}`}>
        <TransformWrapper
          initialScale={1}
          minScale={0.5}
          maxScale={4}
          wheel={{ step: 0.1 }}
          panning={{ velocityDisabled: true }}
        >
          {({ zoomIn, zoomOut }) => (
            <>
              <TransformComponent
                wrapperStyle={{ width: "100%", maxHeight: "400px" }}
                contentStyle={{ width: "100%" }}
              >
                <div dangerouslySetInnerHTML={{ __html: svgHtml }} />
              </TransformComponent>
              <div className="absolute right-2 top-2 z-10 flex gap-1">
                <ToolButton onClick={() => zoomIn()} label="Zoom in">
                  <ZoomIn className="size-3.5" />
                </ToolButton>
                <ToolButton onClick={() => zoomOut()} label="Zoom out">
                  <ZoomOut className="size-3.5" />
                </ToolButton>
                <ToolButton onClick={() => setExpanded(true)} label="Expand">
                  <Maximize2 className="size-3.5" />
                </ToolButton>
              </div>
            </>
          )}
        </TransformWrapper>
      </div>

      {/* Full-screen viewer */}
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
                      // Auto-fit SVG to viewport on mount
                      if (el) {
                        requestAnimationFrame(() => zoomToElement(el, undefined, 100));
                      }
                    }}
                    dangerouslySetInnerHTML={{ __html: svgHtml }}
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
                  <ToolButton
                    onClick={() => setExpanded(false)}
                    label="Close"
                  >
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
