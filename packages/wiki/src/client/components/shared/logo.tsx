/**
 * Branding logo component.
 *
 * Renders the logo configured in .indexion.toml via [wiki] logo_url.
 * SVG logos are fetched and inlined so `currentColor` adapts to the theme.
 * Raster images (png, jpg, etc.) are rendered via <img>.
 * When no logo is configured, nothing is rendered — the title text in
 * the header serves as the brand identifier.
 */

import { useEffect, useMemo, useSyncExternalStore } from "react";
import { useBranding } from "../../lib/branding-context.tsx";

// ── SVG content cache (module singleton) ─────────────────

const svgCache = new Map<string, string | null>();
const svgInflight = new Set<string>();
const svgListeners = new Set<() => void>();
let svgVersion = 0;

function svgSubscribe(cb: () => void): () => void {
  svgListeners.add(cb);
  return () => svgListeners.delete(cb);
}

function svgGetSnapshot(): number {
  return svgVersion;
}

function svgNotify(): void {
  svgVersion++;
  for (const cb of svgListeners) {
    cb();
  }
}

function ensureSvgFetch(url: string): void {
  if (svgCache.has(url) || svgInflight.has(url)) {
    return;
  }
  svgInflight.add(url);
  fetch(url)
    .then((res) => (res.ok ? res.text() : null))
    .then((text) => {
      svgCache.set(url, text);
      svgInflight.delete(url);
      svgNotify();
    })
    .catch(() => {
      svgCache.set(url, null);
      svgInflight.delete(url);
      svgNotify();
    });
}

// ── Component ────────────────────────────────────────────

type Props = {
  readonly className?: string;
};

const isSvgUrl = (url: string): boolean =>
  url.endsWith(".svg") || url.includes(".svg?");

export const Logo = ({
  className = "h-5",
}: Props): React.JSX.Element | null => {
  const { logoUrl, logoAlt } = useBranding();
  const version = useSyncExternalStore(
    svgSubscribe,
    svgGetSnapshot,
    svgGetSnapshot,
  );

  // Initiate fetch (idempotent)
  useEffect(() => {
    if (logoUrl && isSvgUrl(logoUrl)) {
      ensureSvgFetch(logoUrl);
    }
  }, [logoUrl]);

  const svgContent = useMemo(() => {
    void version;
    if (!logoUrl || !isSvgUrl(logoUrl)) {
      return null;
    }
    return svgCache.get(logoUrl) ?? null;
  }, [logoUrl, version]);

  if (!logoUrl) {
    return null;
  }

  // SVG: inline rendering for currentColor support
  if (isSvgUrl(logoUrl) && svgContent) {
    return (
      <span
        className={`inline-flex w-auto ${className}`}
        role="img"
        aria-label={logoAlt ?? ""}
        dangerouslySetInnerHTML={{ __html: svgContent }}
      />
    );
  }

  // Raster / SVG still loading: use <img>
  return (
    <img className={`w-auto ${className}`} src={logoUrl} alt={logoAlt ?? ""} />
  );
};
