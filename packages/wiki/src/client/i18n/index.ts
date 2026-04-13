/**
 * @file Locale resolution — picks the best Dict for a given locale string.
 *
 * Resolution order:
 *   1. Exact match (e.g. "ja" -> ja dict)
 *   2. Language prefix (e.g. "ja-JP" -> ja dict)
 *   3. Fall back to English
 *
 * When locale is "auto" (or null/undefined), navigator.language is used.
 */

import type { Dict } from "./dict.ts";
import { en } from "./en.ts";
import { ja } from "./ja.ts";

const DICTS: Record<string, Dict> = {
  en,
  ja,
};

export const resolveDict = (locale?: string | null): Dict => {
  const tag =
    !locale || locale === "auto" ? (navigator.language ?? "en") : locale;

  // Exact match
  if (tag in DICTS) {
    return DICTS[tag]!;
  }

  // Language prefix (e.g. "ja-JP" -> "ja")
  const prefix = tag.split("-")[0]!;
  if (prefix in DICTS) {
    return DICTS[prefix]!;
  }

  // Fallback
  return en;
};

export { type Dict } from "./dict.ts";
export { DictContext, useDict } from "./dict.ts";
export { en } from "./en.ts";
export { ja } from "./ja.ts";
