#!/usr/bin/env sh
set -eu

repo_root=$(
  CDPATH= cd -- "$(dirname "$0")/.." && pwd
)

threshold=${1:-0.1}
out_root=${2:-"$repo_root/.indexion/state/dogfood/benchmarks"}

run_case() {
  name=$1
  source_path=$2
  impl_path=$3
  work_dir="$out_root/$name"

  "$repo_root/scripts/spec-align-dogfood.sh" \
    "$source_path" \
    "$impl_path" \
    "$work_dir" \
    "$threshold" >/dev/null

  python3 - "$work_dir/status.json" "$name" <<'PY'
import json
import sys

status_path, name = sys.argv[1], sys.argv[2]
with open(status_path) as f:
    data = json.load(f)
summary = data["summary"]
print(
    f"{name}\t"
    f"matched={summary['matched']}\t"
    f"drifted={summary['drifted']}\t"
    f"spec_only={summary['spec_only']}\t"
    f"impl_only={summary['impl_only']}\t"
    f"conflict={summary['conflict']}"
)
PY
}

mkdir -p "$out_root"

printf '%s\n' "threshold=$threshold"
printf '%s\n' "name\tmatched\tdrifted\tspec_only\timpl_only\tconflict"
run_case \
  "rfc3492" \
  "fixtures/project/spec-align-rfc3492/spec/rfc3492.rfc.txt" \
  "fixtures/project/spec-align-rfc3492/typescript"
run_case \
  "rfc2795" \
  "fixtures/project/spec-align-rfc2795/spec/rfc2795.rfc.txt" \
  "fixtures/project/spec-align-rfc2795/typescript"
