#!/usr/bin/env sh
set -eu

repo_root=$(
  CDPATH= cd -- "$(dirname "$0")/.." && pwd
)

cd "$repo_root"
moon build cmd/indexion --target native >/dev/null
exec "$repo_root/_build/native/debug/build/cmd/indexion/indexion.exe" "$@"
