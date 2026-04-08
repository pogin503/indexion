#!/usr/bin/env sh
set -eu

repo_root=$(
  CDPATH= cd -- "$(dirname "$0")/.." && pwd
)

cd "$repo_root"

node --test --experimental-strip-types \
  fixtures/project/spec-align-rfc3492/typescript/punycode.test.ts \
  fixtures/project/spec-align-rfc2795/typescript/keeper.test.ts
