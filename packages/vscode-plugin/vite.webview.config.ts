/**
 * @file Vite build configuration for React webview panels.
 */

import { defineConfig } from "vite";

export default defineConfig({
  build: {
    outDir: "dist/webview",
    rollupOptions: {
      input: {
        settings: "src/webview/settings/app.tsx",
        "plan-results": "src/webview/plan-results/app.tsx",
        search: "src/webview/search/app.tsx",
        explore: "src/webview/explore/app.tsx",
        "wiki-page": "src/webview/wiki-page/app.tsx",
        "wiki-viewer": "src/webview/wiki-viewer/app.tsx",
      },
      output: {
        entryFileNames: "[name].js",
        assetFileNames: "[name][extname]",
      },
    },
    sourcemap: true,
    minify: false,
    cssCodeSplit: false,
  },
  css: {
    modules: {
      localsConvention: "camelCase",
    },
  },
});
