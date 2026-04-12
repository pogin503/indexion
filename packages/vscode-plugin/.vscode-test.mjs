import { defineConfig } from "@vscode/test-cli";
import { resolve } from "node:path";

const projectRoot = resolve(import.meta.dirname, "../..");

export default defineConfig({
  files: "dist/e2e/**/*.test.js",
  workspaceFolder: projectRoot,
  mocha: {
    timeout: 60_000,
  },
});
