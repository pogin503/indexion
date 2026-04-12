/**
 * @file Build integrity tests — verifies the built artifacts are correct.
 *
 * These tests run AFTER build to ensure:
 * 1. dist/extension.js exists and is valid CJS with activate/deactivate exports
 * 2. dist/webview/ contains all expected files
 * 3. package.json references match actual build output
 * 4. No missing files that VS Code would fail to resolve at runtime
 */

import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(__dirname, "..");
const DIST = path.join(ROOT, "dist");

const readPkgJson = () =>
  JSON.parse(fs.readFileSync(path.join(ROOT, "package.json"), "utf-8")) as {
    main: string;
    contributes: {
      commands: Array<{ command: string; title: string }>;
      views: Record<string, Array<{ id: string; name: string }>>;
      viewsContainers: { activitybar: Array<{ id: string; icon: string }> };
    };
  };

describe("build output: extension host", () => {
  it("dist/extension.js exists", () => {
    expect(fs.existsSync(path.join(DIST, "extension.js"))).toBe(true);
  });

  it("dist/extension.js exports activate and deactivate", () => {
    const content = fs.readFileSync(path.join(DIST, "extension.js"), "utf-8");
    expect(content).toContain("exports.activate");
    expect(content).toContain("exports.deactivate");
  });

  it("dist/extension.js is CommonJS (not ESM)", () => {
    const content = fs.readFileSync(path.join(DIST, "extension.js"), "utf-8");
    // CJS uses Object.defineProperty on exports, not export default
    expect(content).toContain("exports");
    // Should NOT have top-level export statements
    expect(content).not.toMatch(/^export\s/m);
  });

  it("dist/extension.js externalizes vscode (does not bundle it)", () => {
    const content = fs.readFileSync(path.join(DIST, "extension.js"), "utf-8");
    // Should require vscode as external
    expect(content).toContain('require("vscode")');
  });

  it("dist/extension.js.map exists (sourcemaps)", () => {
    expect(fs.existsSync(path.join(DIST, "extension.js.map"))).toBe(true);
  });
});

describe("build output: webview", () => {
  const WEBVIEW = path.join(DIST, "webview");

  it("dist/webview/ directory exists", () => {
    expect(fs.existsSync(WEBVIEW)).toBe(true);
  });

  it("plan-results.js exists", () => {
    expect(fs.existsSync(path.join(WEBVIEW, "plan-results.js"))).toBe(true);
  });

  it("settings.js exists", () => {
    expect(fs.existsSync(path.join(WEBVIEW, "settings.js"))).toBe(true);
  });

  it("style.css exists", () => {
    expect(fs.existsSync(path.join(WEBVIEW, "style.css"))).toBe(true);
  });

  it("webview JS files do NOT require vscode (they use acquireVsCodeApi)", () => {
    for (const file of ["plan-results.js", "settings.js"]) {
      const content = fs.readFileSync(path.join(WEBVIEW, file), "utf-8");
      expect(content, `${file} should not require vscode`).not.toContain('require("vscode")');
    }
  });
});

describe("package.json ↔ build consistency", () => {
  const pkg = readPkgJson();

  it("main field points to existing file", () => {
    const mainPath = path.join(ROOT, pkg.main);
    expect(fs.existsSync(mainPath), `${pkg.main} must exist`).toBe(true);
  });

  it("activity bar icon file exists", () => {
    for (const container of pkg.contributes.viewsContainers.activitybar) {
      const iconPath = path.join(ROOT, container.icon);
      expect(fs.existsSync(iconPath), `Icon ${container.icon} must exist`).toBe(true);
    }
  });
});
