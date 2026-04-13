#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
USER_DATA_DIR="/tmp/indexion-dev-user"
EXTENSIONS_DIR="/tmp/indexion-dev-exts"

if ! command -v code >/dev/null 2>&1; then
  echo "Error: VS Code CLI 'code' is required." >&2
  exit 1
fi

# Build unless SKIP_BUILD=1 (set by Makefile which already built).
if [ "${SKIP_BUILD:-}" != "1" ]; then
  echo "[1/3] Building extension..."
  bun run --cwd "$ROOT_DIR" build
else
  echo "[1/3] Build skipped (SKIP_BUILD=1)."
fi

echo "[2/3] Resetting isolated VS Code profile..."
rm -rf "$USER_DATA_DIR" "$EXTENSIONS_DIR"
mkdir -p "$USER_DATA_DIR/User"
cat > "$USER_DATA_DIR/User/settings.json" <<'JSON'
{}
JSON

echo "[3/3] Launching VS Code with development extension..."
code \
  --user-data-dir "$USER_DATA_DIR" \
  --extensions-dir "$EXTENSIONS_DIR" \
  --extensionDevelopmentPath="$ROOT_DIR" \
  "$PROJECT_ROOT"
