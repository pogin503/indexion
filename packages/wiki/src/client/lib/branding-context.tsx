/**
 * @file Branding context — provides theme colors, color-scheme toggling,
 * and branding metadata (title, logo) to all components.
 *
 * Colour scheme lifecycle:
 *   1. Server provides `branding.defaultColorScheme` ("system" | "dark" | "light")
 *   2. User can override via toggle → stored in localStorage
 *   3. "system" follows `prefers-color-scheme` media query
 *   4. CSS variables are injected on `<html>` to apply the active scheme
 */

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  useSyncExternalStore,
} from "react";
import type { Branding, BrandingColorSet } from "@indexion/api-client";
import { resolveAppAssetUrl } from "./asset-url.ts";

// ---------------------------------------------------------------------------
// Built-in colour presets (SoT for default dark/light themes)
// ---------------------------------------------------------------------------

const DARK_DEFAULTS: Required<Record<keyof BrandingColorSet, string>> = {
  background: "oklch(0.145 0 0)",
  foreground: "oklch(0.985 0 0)",
  primary: "oklch(0.985 0 0)",
  accent: "oklch(0.269 0 0)",
};

const LIGHT_DEFAULTS: Required<Record<keyof BrandingColorSet, string>> = {
  background: "oklch(0.985 0 0)",
  foreground: "oklch(0.145 0 0)",
  primary: "oklch(0.205 0 0)",
  accent: "oklch(0.93 0 0)",
};

// Map from BrandingColorSet keys to CSS custom property names.
// Each branding key maps to a primary CSS variable and its semantic aliases.
const COLOR_VAR_MAP: Record<keyof BrandingColorSet, readonly string[]> = {
  background: [
    "--color-background",
    "--color-card",
    "--color-popover",
    "--color-sidebar-background",
  ],
  foreground: [
    "--color-foreground",
    "--color-card-foreground",
    "--color-popover-foreground",
  ],
  primary: ["--color-primary", "--color-sidebar-primary"],
  accent: [
    "--color-accent",
    "--color-secondary",
    "--color-muted",
    "--color-sidebar-accent",
  ],
};

// Derived variables that are computed from the opposing color
const DERIVED_FG_VARS: readonly string[] = [
  "--color-primary-foreground",
  "--color-sidebar-primary-foreground",
];

const DERIVED_ACCENT_FG_VARS: readonly string[] = [
  "--color-accent-foreground",
  "--color-secondary-foreground",
  "--color-sidebar-accent-foreground",
];

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ColorScheme = "dark" | "light";
export type ColorSchemePreference = "dark" | "light" | "system";

export type BrandingContextValue = {
  readonly title: string | null;
  readonly logoUrl: string | null;
  readonly faviconUrl: string | null;
  readonly logoAlt: string | null;
  /** Resolved scheme (always "dark" or "light") */
  readonly colorScheme: ColorScheme;
  /** User preference (may be "system") */
  readonly colorSchemePreference: ColorSchemePreference;
  readonly setColorSchemePreference: (pref: ColorSchemePreference) => void;
};

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

const BrandingContext = createContext<BrandingContextValue | null>(null);

export const useBranding = (): BrandingContextValue => {
  const ctx = useContext(BrandingContext);
  if (!ctx) {
    throw new Error("useBranding must be used within a BrandingProvider");
  }
  return ctx;
};

// ---------------------------------------------------------------------------
// localStorage key
// ---------------------------------------------------------------------------

const LS_KEY = "indexion-color-scheme";

const loadPreference = (
  serverDefault: string | null,
): ColorSchemePreference => {
  const stored = localStorage.getItem(LS_KEY);
  if (stored === "dark" || stored === "light" || stored === "system") {
    return stored;
  }
  if (
    serverDefault === "dark" ||
    serverDefault === "light" ||
    serverDefault === "system"
  ) {
    return serverDefault;
  }
  return "system";
};

// ---------------------------------------------------------------------------
// CSS variable injection
// ---------------------------------------------------------------------------

const applyColors = (scheme: ColorScheme, branding: Branding | null): void => {
  const html = document.documentElement;

  // Set class for CSS-only selectors (e.g. prose dark:prose-invert)
  html.classList.remove("dark", "light");
  html.classList.add(scheme);

  const defaults = scheme === "dark" ? DARK_DEFAULTS : LIGHT_DEFAULTS;
  const overrides: BrandingColorSet =
    scheme === "dark"
      ? (branding?.colors.dark ?? {
          background: null,
          foreground: null,
          primary: null,
          accent: null,
        })
      : (branding?.colors.light ?? {
          background: null,
          foreground: null,
          primary: null,
          accent: null,
        });

  // Apply primary color variables
  for (const [key, vars] of Object.entries(COLOR_VAR_MAP)) {
    const k = key as keyof BrandingColorSet;
    const value = overrides[k] ?? defaults[k];
    for (const v of vars) {
      html.style.setProperty(v, value);
    }
  }

  // Derived: primary-foreground = background color (inverted)
  const bg = overrides.background ?? defaults.background;
  for (const v of DERIVED_FG_VARS) {
    html.style.setProperty(v, bg);
  }

  // Derived: accent-foreground = foreground color
  const fg = overrides.foreground ?? defaults.foreground;
  for (const v of DERIVED_ACCENT_FG_VARS) {
    html.style.setProperty(v, fg);
  }

  // Muted foreground — a mid-tone between bg and fg
  const mutedFg = scheme === "dark" ? "oklch(0.708 0 0)" : "oklch(0.45 0 0)";
  html.style.setProperty("--color-muted-foreground", mutedFg);
  html.style.setProperty("--color-sidebar-foreground", mutedFg);

  // Border / input / ring — derived from accent
  const accent = overrides.accent ?? defaults.accent;
  html.style.setProperty("--color-border", accent);
  html.style.setProperty("--color-input", accent);
  html.style.setProperty("--color-sidebar-border", accent);

  const ring = scheme === "dark" ? "oklch(0.556 0 0)" : "oklch(0.556 0 0)";
  html.style.setProperty("--color-ring", ring);
  html.style.setProperty("--color-sidebar-ring", ring);
};

// ---------------------------------------------------------------------------
// System scheme subscription (useSyncExternalStore)
// ---------------------------------------------------------------------------

const mql =
  typeof globalThis.matchMedia === "function"
    ? globalThis.matchMedia("(prefers-color-scheme: light)")
    : null;

function subscribeSystemScheme(cb: () => void): () => void {
  mql?.addEventListener("change", cb);
  return () => mql?.removeEventListener("change", cb);
}

function getSystemSchemeSnapshot(): ColorScheme {
  return mql?.matches ? "light" : "dark";
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

type ProviderProps = {
  readonly branding: Branding | null;
  readonly children: React.ReactNode;
};

export const BrandingProvider = ({
  branding,
  children,
}: ProviderProps): React.JSX.Element => {
  const [pref, setPref] = useState<ColorSchemePreference>(() =>
    loadPreference(branding?.defaultColorScheme ?? null),
  );

  // System scheme via useSyncExternalStore (no setState for external events)
  const systemScheme = useSyncExternalStore(
    subscribeSystemScheme,
    getSystemSchemeSnapshot,
    () => "dark" as const,
  );

  // Derived: resolve preference to concrete scheme
  const scheme: ColorScheme = pref === "system" ? systemScheme : pref;

  // Persist preference
  const setColorSchemePreference = useCallback(
    (next: ColorSchemePreference) => {
      setPref(next);
      localStorage.setItem(LS_KEY, next);
    },
    [],
  );

  // Apply CSS variables whenever scheme or branding changes
  useEffect(() => {
    applyColors(scheme, branding);
  }, [scheme, branding]);

  // Update document.title from branding
  useEffect(() => {
    if (branding?.title) {
      document.title = branding.title;
    }
  }, [branding?.title]);

  useEffect(() => {
    const faviconUrl = resolveAppAssetUrl(branding?.faviconUrl ?? null);
    if (!faviconUrl) {
      return;
    }
    let link = document.querySelector<HTMLLinkElement>('link[rel="icon"]');
    if (!link) {
      link = document.createElement("link");
      link.rel = "icon";
      document.head.append(link);
    }
    link.href = faviconUrl;
    const mimeTypes: Record<string, string> = {
      ".svg": "image/svg+xml",
      ".ico": "image/x-icon",
    };
    const ext = Object.keys(mimeTypes).find((e) => faviconUrl.endsWith(e));
    if (ext) {
      link.type = mimeTypes[ext];
    } else {
      link.removeAttribute("type");
    }
  }, [branding?.faviconUrl]);

  const value = useMemo<BrandingContextValue>(
    () => ({
      title: branding?.title ?? null,
      logoUrl: resolveAppAssetUrl(branding?.logoUrl ?? null),
      faviconUrl: resolveAppAssetUrl(branding?.faviconUrl ?? null),
      logoAlt: branding?.logoAlt ?? null,
      colorScheme: scheme,
      colorSchemePreference: pref,
      setColorSchemePreference,
    }),
    [branding, scheme, pref, setColorSchemePreference],
  );

  return <BrandingContext value={value}>{children}</BrandingContext>;
};
