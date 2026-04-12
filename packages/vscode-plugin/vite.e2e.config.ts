/**
 * @file Vite build configuration for E2E tests.
 *
 * Compiles src/e2e/*.test.ts → dist/e2e/*.test.js for @vscode/test-cli.
 */

import { resolve } from "node:path";
import { defineConfig } from "vite";
import { readdirSync } from "node:fs";

const e2eDir = resolve(__dirname, "src/e2e");
const entries: Record<string, string> = {};
for (const f of readdirSync(e2eDir).filter((n) => n.endsWith(".test.ts"))) {
  entries[f.replace(".ts", "")] = resolve(e2eDir, f);
}

export default defineConfig({
  resolve: {
    alias: {
      "@indexion/api-client": resolve(__dirname, "../api-client/src/index.ts"),
    },
  },
  build: {
    outDir: "dist/e2e",
    lib: {
      entry: entries,
      formats: ["cjs"],
    },
    rollupOptions: {
      external: ["vscode", "mocha", "assert", /^node:.+/],
    },
    sourcemap: true,
    minify: false,
  },
});
