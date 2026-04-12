/**
 * @file Vitest testing framework configuration.
 *
 * Uses happy-dom for webview React component tests
 * and provides VSCode API mocks via setup file.
 */

import path from "node:path";
import { defineConfig } from "vitest/config";
export default defineConfig({
  resolve: {
    alias: {
      vscode: path.resolve(__dirname, "src/test-utils/vscode-mock.ts"),
    },
  },
  test: {
    globals: true,
    environment: "happy-dom",
    setupFiles: ["src/webview/test-setup.ts"],
    css: {
      modules: { classNameStrategy: "non-scoped" },
    },
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    exclude: ["src/e2e/**"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      reportsDirectory: "coverage",
      include: ["src/**/*.{ts,tsx}"],
    },
  },
});
