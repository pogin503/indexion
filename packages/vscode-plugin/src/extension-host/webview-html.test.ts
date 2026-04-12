/**
 * @file Tests for the webview HTML builder.
 */

import { describe, it, expect } from "vitest";
import { generateNonce, buildWebviewHtml } from "./webview-html.ts";

describe("generateNonce", () => {
  it("returns a 32-character string", () => {
    const nonce = generateNonce();
    expect(nonce).toHaveLength(32);
  });

  it("contains only alphanumeric characters", () => {
    const nonce = generateNonce();
    expect(nonce).toMatch(/^[A-Za-z0-9]+$/);
  });

  it("generates different values each call", () => {
    const a = generateNonce();
    const b = generateNonce();
    expect(a).not.toBe(b);
  });
});

describe("buildWebviewHtml", () => {
  const mockWebview = {
    cspSource: "https://test.csp",
  } as unknown as import("vscode").Webview;

  const mockUri = (path: string) =>
    ({
      toString: () => path,
    }) as unknown as import("vscode").Uri;

  it("includes script and style URIs", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/dist/app.js"),
      styleUri: mockUri("/dist/style.css"),
      title: "Test",
    });
    expect(html).toContain("/dist/app.js");
    expect(html).toContain("/dist/style.css");
  });

  it("includes the title", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/app.js"),
      styleUri: mockUri("/style.css"),
      title: "My Panel",
    });
    expect(html).toContain("<title>My Panel</title>");
  });

  it("includes CSP with nonce", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/app.js"),
      styleUri: mockUri("/style.css"),
      title: "Test",
    });
    expect(html).toContain("Content-Security-Policy");
    expect(html).toContain("script-src 'nonce-");
    expect(html).toContain("https://test.csp");
  });

  it("does not include unsafe-inline by default", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/app.js"),
      styleUri: mockUri("/style.css"),
      title: "Test",
    });
    expect(html).not.toContain("unsafe-inline");
  });

  it("includes unsafe-inline when allowInlineStyles is true", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/app.js"),
      styleUri: mockUri("/style.css"),
      title: "Test",
      allowInlineStyles: true,
    });
    expect(html).toContain("'unsafe-inline'");
  });

  it("has a root div", () => {
    const html = buildWebviewHtml({
      webview: mockWebview,
      scriptUri: mockUri("/app.js"),
      styleUri: mockUri("/style.css"),
      title: "Test",
    });
    expect(html).toContain('<div id="root"></div>');
  });
});
