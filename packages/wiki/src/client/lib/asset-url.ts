/**
 * Resolve URLs returned by the API against Vite's base path.
 *
 * In static GitHub Pages builds, API-shaped files live under BASE_URL
 * (for example /indexion/api/...). The server still returns root-relative
 * /api/... paths because those are correct for local `indexion serve`.
 */
export const resolveAppAssetUrl = (url: string | null): string | null => {
  if (!url) {
    return null;
  }
  if (
    url.startsWith("http://") ||
    url.startsWith("https://") ||
    url.startsWith("data:") ||
    url.startsWith("blob:")
  ) {
    return url;
  }
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  if (url.startsWith("/api/")) {
    return `${base}${url}`;
  }
  return url;
};
