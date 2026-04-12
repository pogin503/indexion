#!/usr/bin/env bash
# Quick smoke test for wiki API endpoints.
# Starts the indexion server, verifies wiki endpoints return expected shapes,
# then stops the server.
#
# Usage:
#   ./scripts/test-wiki-api.sh
#
# Requires: indexion native binary (moon build) and curl/jq.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PORT=0

echo "[1/4] Building indexion..."
(cd "$PROJECT_ROOT" && moon build --target native 2>&1 | tail -1)

BINARY="$PROJECT_ROOT/_build/native/debug/build/cmd/indexion/indexion.exe"
if [ ! -f "$BINARY" ]; then
  echo "Error: binary not found at $BINARY" >&2
  exit 1
fi

echo "[2/4] Starting server..."
# Use port 0 to auto-assign; parse the actual port from stdout
"$BINARY" serve --cors --port=0 --specs=kgfs "$PROJECT_ROOT" &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null" EXIT

# Wait for server and discover port
sleep 1
ACTUAL_PORT=""
for i in $(seq 1 20); do
  ACTUAL_PORT=$(lsof -p $SERVER_PID -i -P -n 2>/dev/null | grep LISTEN | awk '{print $9}' | grep -o '[0-9]*$' | head -1)
  if [ -n "$ACTUAL_PORT" ]; then
    break
  fi
  sleep 0.5
done

if [ -z "$ACTUAL_PORT" ]; then
  echo "Error: could not determine server port" >&2
  exit 1
fi

BASE="http://127.0.0.1:${ACTUAL_PORT}/api"
echo "  Server on port $ACTUAL_PORT"

# Wait for health
for i in $(seq 1 30); do
  if curl -sf "$BASE/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "[3/4] Testing wiki API endpoints..."
FAIL=0

# /api/wiki/nav
NAV=$(curl -sf "$BASE/wiki/nav")
NAV_OK=$(echo "$NAV" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ok','MISSING'))")
NAV_COUNT=$(echo "$NAV" | python3 -c "import json,sys; d=json.load(sys.stdin); pages=d.get('data',{}).get('pages',[]); print(len(pages))" 2>/dev/null || echo "0")

if [ "$NAV_OK" = "True" ] && [ "$NAV_COUNT" -gt 0 ]; then
  echo "  ✓ /api/wiki/nav: ok=true, pages=$NAV_COUNT"
else
  echo "  ✗ /api/wiki/nav: ok=$NAV_OK, pages=$NAV_COUNT"
  FAIL=1
fi

# Extract first page ID for page test
FIRST_PAGE=$(echo "$NAV" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['data']['pages'][0]['id'])" 2>/dev/null || echo "")

# /api/wiki/pages/{id}
if [ -n "$FIRST_PAGE" ]; then
  PAGE=$(curl -sf "$BASE/wiki/pages/$FIRST_PAGE")
  PAGE_OK=$(echo "$PAGE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ok','MISSING'))")
  PAGE_TITLE=$(echo "$PAGE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('title','MISSING'))" 2>/dev/null || echo "MISSING")

  if [ "$PAGE_OK" = "True" ] && [ "$PAGE_TITLE" != "MISSING" ]; then
    echo "  ✓ /api/wiki/pages/$FIRST_PAGE: ok=true, title='$PAGE_TITLE'"
  else
    echo "  ✗ /api/wiki/pages/$FIRST_PAGE: ok=$PAGE_OK, title=$PAGE_TITLE"
    FAIL=1
  fi

  # Verify response shape has required fields
  FIELDS_OK=$(echo "$PAGE" | python3 -c "
import json, sys
d = json.load(sys.stdin)['data']
required = ['id', 'title', 'content', 'sources', 'headings', 'children', 'parent']
missing = [f for f in required if f not in d]
print('OK' if not missing else 'MISSING: ' + ', '.join(missing))
" 2>/dev/null || echo "PARSE_ERROR")

  if [ "$FIELDS_OK" = "OK" ]; then
    echo "  ✓ Page response has all required fields"
  else
    echo "  ✗ Page response: $FIELDS_OK"
    FAIL=1
  fi
else
  echo "  ✗ Could not extract first page ID for page test"
  FAIL=1
fi

# /api/wiki/search (POST)
SEARCH=$(curl -sf -X POST -H 'Content-Type: application/json' -d '{"query":"overview","topK":5}' "$BASE/wiki/search")
SEARCH_OK=$(echo "$SEARCH" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ok','MISSING'))")

if [ "$SEARCH_OK" = "True" ]; then
  echo "  ✓ /api/wiki/search: ok=true"
else
  echo "  ✗ /api/wiki/search: ok=$SEARCH_OK"
  # Search may legitimately have no results — only fail if ok!=true
  FAIL=1
fi

echo "[4/4] Cleanup..."
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "All wiki API tests passed."
else
  echo ""
  echo "Some wiki API tests failed." >&2
  exit 1
fi
