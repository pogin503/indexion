/**
 * @file Hook that fetches a KGF spec and tokenizes code using the
 * MoonBit-compiled kgf-tokenizer.
 *
 * Specs are cached per language so repeat renders don't re-fetch.
 */

import { useEffect, useState } from "react";
import { tokenize } from "@kgf-tokenizer";
import { client } from "../client.ts";

type Tok = { kind: string; text: string; pos: number };

const specCache = new Map<string, string>();

async function fetchSpec(lang: string): Promise<string | null> {
  const cached = specCache.get(lang);
  if (cached !== undefined) {
    return cached;
  }
  const res = await client.get<string>(`/kgf/specs/${lang}`);
  if (!res.ok) {
    return null;
  }
  specCache.set(lang, res.data);
  return res.data;
}

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

export type HighlightResult = {
  status: "idle" | "loading" | "ready" | "unsupported";
  segments: Array<{ text: string; color: string | null }>;
};

/**
 * Given a language name and source code, returns colored segments.
 * Falls back to unstyled text when the spec isn't available.
 */
export function useKgfHighlight(
  lang: string | null,
  code: string,
): HighlightResult {
  const [result, setResult] = useState<HighlightResult>({
    status: "idle",
    segments: [{ text: code, color: null }],
  });

  useEffect(() => {
    if (!lang) {
      setResult({
        status: "unsupported",
        segments: [{ text: code, color: null }],
      });
      return;
    }
    let cancelled = false;
    setResult((prev) => ({ ...prev, status: "loading" }));

    fetchSpec(lang).then((spec) => {
      if (cancelled) {
        return;
      }
      if (!spec) {
        setResult({
          status: "unsupported",
          segments: [{ text: code, color: null }],
        });
        return;
      }
      const raw = tokenize(spec, code);
      const tokens: Tok[] = JSON.parse(raw);
      const segments: Array<{ text: string; color: string | null }> = [];
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
      setResult({ status: "ready", segments });
    });

    return () => {
      cancelled = true;
    };
  }, [lang, code]);

  return result;
}
