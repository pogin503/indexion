/**
 * @file Tests for wiki message types and converters.
 *
 * The server returns wiki search results as section-scoped hits:
 *   { section: { id, title, content, page_id, level }, score }
 *
 * toWikiSearchHits flattens this into a typed WikiSearchHit.
 */

import { describe, it, expect } from "vitest";
import { toWikiSearchHits } from "./messages.ts";

describe("toWikiSearchHits", () => {
  it("converts a complete hit", () => {
    const raw = [
      {
        section: {
          id: "overview#intro-1",
          title: "Introduction",
          content: "  indexion\nis a tool for  \t codebases.",
          page_id: "overview",
          level: 2,
        },
        score: 0.75,
      },
    ];
    const [hit] = toWikiSearchHits(raw);
    expect(hit).toEqual({
      pageId: "overview",
      sectionId: "overview#intro-1",
      title: "Introduction",
      snippet: "indexion is a tool for codebases.",
      level: 2,
      score: 0.75,
    });
  });

  it("falls back to page_id for title when title missing", () => {
    const raw = [{ section: { id: "s1", page_id: "foo", content: "" }, score: 0.1 }];
    const [hit] = toWikiSearchHits(raw);
    expect(hit?.title).toBe("foo");
  });

  it("produces empty strings when section is missing", () => {
    const raw = [{}];
    const [hit] = toWikiSearchHits(raw);
    expect(hit).toEqual({
      pageId: "",
      sectionId: "",
      title: "",
      snippet: "",
      level: 0,
      score: 0,
    });
  });

  it("truncates long snippets with ellipsis", () => {
    const long = "a".repeat(200);
    const raw = [{ section: { id: "s", page_id: "p", content: long } }];
    const [hit] = toWikiSearchHits(raw);
    expect(hit?.snippet.length).toBe(120);
    expect(hit?.snippet.endsWith("…")).toBe(true);
  });

  it("handles empty array", () => {
    expect(toWikiSearchHits([])).toEqual([]);
  });

  it("preserves order across multiple hits", () => {
    const raw = [
      { section: { id: "a#1", page_id: "a", title: "Alpha", content: "first" }, score: 0.9 },
      { section: { id: "b#1", page_id: "b", title: "Beta", content: "second" }, score: 0.5 },
      { section: { id: "c#1", page_id: "c", title: "Gamma", content: "third" }, score: 0.3 },
    ];
    const result = toWikiSearchHits(raw);
    expect(result.map((h) => h.pageId)).toEqual(["a", "b", "c"]);
    expect(result.map((h) => h.score)).toEqual([0.9, 0.5, 0.3]);
  });

  it("tolerates non-numeric score and level", () => {
    const raw = [{ section: { id: "s", page_id: "p", content: "", level: "2" }, score: null }];
    const [hit] = toWikiSearchHits(raw);
    expect(hit?.level).toBe(0);
    expect(hit?.score).toBe(0);
  });
});
