/**
 * @file Vite build configuration for the VSCode extension host.
 */

import { resolve } from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  resolve: {
    alias: {
      "@indexion/api-client": resolve(__dirname, "../api-client/src/index.ts"),
    },
  },
  build: {
    outDir: "dist",
    lib: {
      entry: "src/extension.ts",
      formats: ["cjs"],
      fileName: "extension",
    },
    rollupOptions: {
      external: ["vscode", /^node:.+/],
    },
    sourcemap: true,
    minify: false,
  },
});
