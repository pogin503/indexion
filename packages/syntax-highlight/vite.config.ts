import path from "node:path";
import fs from "node:fs";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const artifactPath = path.resolve(
  __dirname,
  "../../_build/js/debug/build/cmd/kgf-tokenizer/kgf-tokenizer.js",
);
const hasArtifact = fs.existsSync(artifactPath);

if (!hasArtifact) {
  console.warn(
    "\n���  kgf-tokenizer artifact not found. Syntax highlighting will use the stub.\n" +
      "   Run `moon build --target js` from the repo root to build it.\n",
  );
}

const kgfAlias = hasArtifact
  ? { "@indexion/kgf-tokenizer": artifactPath }
  : {};

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: kgfAlias,
  },
  optimizeDeps: {
    // Prevent Vite from pre-bundling kgf-tokenizer via workspace symlink.
    // The alias must take precedence over the symlinked package.
    exclude: ["@indexion/kgf-tokenizer"],
  },
  server: {
    port: 5175,
  },
});
