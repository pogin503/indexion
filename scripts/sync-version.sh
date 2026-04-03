#!/bin/sh
# Sync version from moon.mod.json (SoT) to src/update/version.mbt
# Run this before building to ensure version consistency.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MOD_JSON="$ROOT/moon.mod.json"
VERSION_MBT="$ROOT/src/update/version.mbt"

# Extract version from moon.mod.json
VERSION=$(grep '"version"' "$MOD_JSON" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from $MOD_JSON" >&2
  exit 1
fi

# Check current version in version.mbt
CURRENT=$(grep 'current_version' "$VERSION_MBT" | sed 's/.*"\([^"]*\)".*/\1/')

if [ "$VERSION" = "$CURRENT" ]; then
  exit 0
fi

echo "Syncing version: $CURRENT -> $VERSION"

# Generate version.mbt from template
sed -i.bak "s/pub let current_version : String = \".*\"/pub let current_version : String = \"$VERSION\"/" "$VERSION_MBT"
rm -f "$VERSION_MBT.bak"
