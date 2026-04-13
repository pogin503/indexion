/**
 * @file Hook that fetches a KGF spec and tokenizes code.
 *
 * Specs are managed by an external cache (module singleton).
 * The hook subscribes to cache updates via useSyncExternalStore.
 * Fetch initiation happens in useEffect (side effect), but state
 * updates go through the external store — no setState in effects.
 *
 * Resolution order:
 *   1. Exact language name (e.g. "typescript")
 *   2. "universal" fallback spec
 *   3. Plain text (no highlighting)
 *
 * If no KgfSpecProvider is present, falls back to plain text.
 * All fetch/tokenize errors are logged to console.error.
 */

import { useEffect, useMemo, useSyncExternalStore } from "react";
import { tokenize } from "@indexion/kgf-tokenizer";
import { useKgfSpecFetcher, type FetchKgfSpec } from "./highlight-context.ts";

type Tok = { kind: string; text: string; pos: number };

const UNIVERSAL = "universal";

// ─── Spec cache (module-level singleton) ────────────────

type CacheEntry =
  | { readonly state: "resolved"; readonly spec: string }
  | { readonly state: "empty" };

const cache = new Map<string, CacheEntry>();
const inflight = new Set<string>();
const listeners = new Set<() => void>();
let snapshotVersion = 0;

function subscribe(cb: () => void): () => void {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

function getSnapshot(): number {
  return snapshotVersion;
}

function notifyListeners(): void {
  snapshotVersion++;
  for (const cb of listeners) {
    cb();
  }
}

/**
 * Fetch spec for lang (with universal fallback), update cache,
 * and notify subscribers. Safe to call multiple times — deduped
 * by the inflight set.
 */
function ensureSpec(lang: string, fetchSpec: FetchKgfSpec): void {
  if (cache.has(lang) || inflight.has(lang)) {
    return;
  }
  inflight.add(lang);
  fetchAndCache(lang, fetchSpec);
}

async function fetchAndCache(
  lang: string,
  fetchSpec: FetchKgfSpec,
): Promise<void> {
  try {
    const spec = await fetchSpec(lang);
    if (spec) {
      cache.set(lang, { state: "resolved", spec });
      inflight.delete(lang);
      notifyListeners();
      return;
    }
  } catch (err: unknown) {
    console.error(`[syntax-highlight] Failed to fetch spec "${lang}":`, err);
  }

  // Fallback to universal (unless we already tried universal)
  if (lang !== UNIVERSAL) {
    const universal = await resolveUniversal(fetchSpec);
    cache.set(lang, universal);
  } else {
    cache.set(lang, { state: "empty" });
  }
  inflight.delete(lang);
  notifyListeners();
}

async function resolveUniversal(fetchSpec: FetchKgfSpec): Promise<CacheEntry> {
  const existing = cache.get(UNIVERSAL);
  if (existing) {
    return existing;
  }

  try {
    const spec = await fetchSpec(UNIVERSAL);
    const entry: CacheEntry = spec
      ? { state: "resolved", spec }
      : { state: "empty" };
    cache.set(UNIVERSAL, entry);
    return entry;
  } catch (err: unknown) {
    console.error(`[syntax-highlight] Failed to fetch universal spec:`, err);
    const entry: CacheEntry = { state: "empty" };
    cache.set(UNIVERSAL, entry);
    return entry;
  }
}

// ─── Color mapping ──────────────────────────────────────

/** FNV-1a hash → deterministic HSL color for a token kind (dark theme). */
function colorForKind(kind: string): string {
  const FNV_OFFSET = 0x811c9dc5;
  const FNV_PRIME = 0x01000193;
  let h = FNV_OFFSET;
  for (let i = 0; i < kind.length; i++) {
    h = Math.imul(h ^ kind.charCodeAt(i), FNV_PRIME) >>> 0;
  }
  const hue = h % 360;
  const sat = 55 + ((h >>> 8) % 25);
  const light = 55 + ((h >>> 16) % 15);
  return `hsl(${hue},${sat}%,${light}%)`;
}

// ─── Types ──────────────────────────────────────────────

export type HighlightSegment = {
  readonly text: string;
  readonly color: string | null;
};

export type HighlightResult = {
  readonly status: "idle" | "loading" | "ready" | "unsupported";
  readonly segments: ReadonlyArray<HighlightSegment>;
};

// ─── Tokenization ───────────────────────────────────────

function tokenizeToResult(spec: string, code: string): HighlightResult {
  try {
    const raw = tokenize(spec, code);
    const tokens: Tok[] = JSON.parse(raw);
    if (tokens.length === 0 && code.length > 0) {
      console.warn(
        `[syntax-highlight] Tokenizer returned 0 tokens for ${code.length} chars of code. ` +
          `This usually means the kgf-tokenizer stub is active — run \`moon build --target js\`.`,
      );
    }
    const segments: Array<HighlightSegment> = [];
    let lastEnd = 0;
    for (const tok of tokens) {
      if (tok.pos > lastEnd) {
        segments.push({ text: code.slice(lastEnd, tok.pos), color: null });
      }
      segments.push({ text: tok.text, color: colorForKind(tok.kind) });
      lastEnd = tok.pos + tok.text.length;
    }
    if (lastEnd < code.length) {
      segments.push({ text: code.slice(lastEnd), color: null });
    }
    return { status: "ready", segments };
  } catch (err: unknown) {
    console.error(`[syntax-highlight] Tokenization failed:`, err);
    return { status: "unsupported", segments: [{ text: code, color: null }] };
  }
}

// ─── Hook ───────────────────────────────────────────────

/**
 * Given a language name and source code, returns colored segments.
 *
 * - useEffect: initiates fetch (side effect), writes to external cache
 * - useSyncExternalStore: subscribes to cache updates (no setState)
 * - useMemo: derives result from cache (pure)
 */
export function useKgfHighlight(
  lang: string | null,
  code: string,
): HighlightResult {
  const fetchSpec = useKgfSpecFetcher();

  // Subscribe to external cache — re-renders when any spec resolves.
  // The version number is used as a useMemo dependency to ensure
  // the derived result recomputes when cache entries change.
  const version = useSyncExternalStore(subscribe, getSnapshot, getSnapshot);

  // Side effect: ensure the spec is being fetched
  useEffect(() => {
    if (lang && fetchSpec) {
      ensureSpec(lang, fetchSpec);
    }
  }, [lang, fetchSpec]);

  // Pure derivation from cache
  return useMemo((): HighlightResult => {
    // version is read to satisfy deps — its value change triggers recompute
    void version;

    if (!lang || !fetchSpec) {
      return { status: "unsupported", segments: [{ text: code, color: null }] };
    }

    const entry = cache.get(lang);
    if (!entry) {
      return { status: "loading", segments: [{ text: code, color: null }] };
    }

    switch (entry.state) {
      case "resolved":
        return tokenizeToResult(entry.spec, code);
      case "empty":
        return {
          status: "unsupported",
          segments: [{ text: code, color: null }],
        };
    }
  }, [lang, code, fetchSpec, version]);
}
