import path from "node:path";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

const isStaticMode = !!process.env.VITE_STATIC_MODE;

export default defineConfig({
  base: isStaticMode ? "/indexion/" : "/",
  plugins: [react(), tailwindcss()],
  root: "src/client",
  resolve: {
    conditions: ["bun", "module"],
    alias: {
      "@kgf-tokenizer": path.resolve(
        __dirname,
        "../../_build/js/debug/build/cmd/kgf-tokenizer/kgf-tokenizer.js",
      ),
    },
  },
  build: {
    outDir: "../../dist/client",
    emptyOutDir: true,
    rollupOptions: {
      output: {
        manualChunks: {
          three: ["three"],
        },
      },
    },
  },
  server: {
    port: 5173,
    proxy: {
      "/api": "http://localhost:3741",
    },
  },
});
