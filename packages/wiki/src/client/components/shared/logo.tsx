/**
 * Branding logo component.
 *
 * Renders the logo configured in .indexion.toml via [wiki] logo_url.
 * SVG logos are fetched and inlined so `currentColor` adapts to the theme.
 * Raster images (png, jpg, etc.) are rendered via <img>.
 * When no logo is configured, nothing is rendered — the title text in
 * the header serves as the brand identifier.
 */

import { useState, useEffect } from "react";
import { useBranding } from "../../lib/branding-context.tsx";

type Props = {
  readonly className?: string;
};

const isSvgUrl = (url: string): boolean =>
  url.endsWith(".svg") || url.includes(".svg?");

export const Logo = ({ className = "h-5" }: Props): React.JSX.Element | null => {
  const { logoUrl, logoAlt } = useBranding();
  const [svgContent, setSvgContent] = useState<string | null>(null);

  useEffect(() => {
    if (!logoUrl || !isSvgUrl(logoUrl)) {
      setSvgContent(null);
      return;
    }
    let cancelled = false;
    fetch(logoUrl)
      .then((res) => (res.ok ? res.text() : null))
      .then((text) => {
        if (!cancelled && text) {
          setSvgContent(text);
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [logoUrl]);

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
    <img
      className={`w-auto ${className}`}
      src={logoUrl}
      alt={logoAlt ?? ""}
    />
  );
};
