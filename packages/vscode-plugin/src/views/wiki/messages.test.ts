/**
 * @file Tests for wiki message types and converters.
 *
 * Verifies that toWikiSearchHits correctly converts raw API responses
 * to typed WikiSearchHit array, including edge cases with missing fields.
 */

import { describe, it, expect } from "vitest";
import { toWikiSearchHits } from "./messages.ts";

describe("toWikiSearchHits", () => {
  it("converts a complete hit", () => {
    const raw = [{ id: "page-1", title: "Overview", snippet: "An overview of..." }];
    const result = toWikiSearchHits(raw);
    expect(result).toEqual([{ id: "page-1", title: "Overview", snippet: "An overview of..." }]);
  });

  it("uses id as fallback when title is missing", () => {
    const raw = [{ id: "page-2" }];
    const result = toWikiSearchHits(raw);
    expect(result).toEqual([{ id: "page-2", title: "page-2", snippet: undefined }]);
  });

  it("defaults id and title to empty string when both missing", () => {
    const raw = [{}];
    const result = toWikiSearchHits(raw);
    expect(result).toEqual([{ id: "", title: "", snippet: undefined }]);
  });

  it("omits snippet when absent", () => {
    const raw = [{ id: "p", title: "T" }];
    const result = toWikiSearchHits(raw);
    expect(result[0]?.snippet).toBeUndefined();
  });

  it("handles empty array", () => {
    expect(toWikiSearchHits([])).toEqual([]);
  });

  it("converts multiple hits preserving order", () => {
    const raw = [
      { id: "a", title: "Alpha", snippet: "first" },
      { id: "b", title: "Beta" },
      { id: "c", title: "Gamma", snippet: "third" },
    ];
    const result = toWikiSearchHits(raw);
    expect(result).toHaveLength(3);
    expect(result.map((h) => h.id)).toEqual(["a", "b", "c"]);
    expect(result[1]?.snippet).toBeUndefined();
  });
});
