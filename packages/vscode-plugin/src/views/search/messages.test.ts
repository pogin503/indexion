/**
 * @file Tests for search view message types and converters.
 */

import { digestMatchToSearchResult } from "./messages.ts";

describe("digestMatchToSearchResult", () => {
  it("converts a DigestMatch to SearchResultItem", () => {
    const match = {
      name: "parseConfig",
      file: "/src/config/parser.ts",
      score: 0.85,
      summary: "Parses the configuration file into a typed object",
    };
    const result = digestMatchToSearchResult(match);
    expect(result.label).toBe("parseConfig");
    expect(result.description).toBe("/src/config/parser.ts");
    expect(result.detail).toBe("Parses the configuration file into a typed object");
    expect(result.filePath).toBe("/src/config/parser.ts");
    expect(result.score).toBe(0.85);
  });

  it("preserves all fields from the match", () => {
    const match = {
      name: "formatOutput",
      file: "/src/utils/format.ts",
      score: 0.42,
      summary: "Formats output for display",
    };
    const result = digestMatchToSearchResult(match);
    expect(result).toEqual({
      label: "formatOutput",
      description: "/src/utils/format.ts",
      detail: "Formats output for display",
      filePath: "/src/utils/format.ts",
      score: 0.42,
    });
  });
});
