#!/usr/bin/env sh
set -eu

repo_root=$(
  CDPATH= cd -- "$(dirname "$0")/.." && pwd
)

thresholds=${*:-"0.1 0.05 0.0"}
work_root=$(mktemp -d "${TMPDIR:-/tmp}/indexion-rfc-regression.XXXXXX")
trap 'rm -rf "$work_root"' EXIT INT TERM

run_draft() {
  source_path=$1
  draft_path=$2
  "$repo_root/scripts/indexion-native.sh" spec draft \
    --specs-dir=kgfs \
    --output="$draft_path" \
    "$source_path" >/dev/null
}

run_status_json() {
  threshold=$1
  spec_path=$2
  impl_path=$3
  cache_dir=$4
  output_path=$5
  "$repo_root/scripts/indexion-native.sh" spec align status \
    --specs-dir=kgfs \
    --cache-dir="$cache_dir" \
    --threshold="$threshold" \
    --fail-on=none \
    --format=json \
    "$spec_path" \
    "$impl_path" >"$output_path"
}

assert_zero_drift() {
  status_path=$1
  python3 - "$status_path" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    data = json.load(f)
summary = data["summary"]
if any(summary[key] != 0 for key in ("drifted", "spec_only", "impl_only", "conflict")):
    print(summary)
    sys.exit(1)
PY
}

assert_detects_drift() {
  threshold=$1
  spec_path=$2
  impl_path=$3
  cache_dir=$4
  output_path=$5
  "$repo_root/scripts/indexion-native.sh" spec align status \
    --specs-dir=kgfs \
    --cache-dir="$cache_dir" \
    --threshold="$threshold" \
    --fail-on=drifted \
    --format=json \
    "$spec_path" \
    "$impl_path" >"$output_path" && exit 1 || true
  python3 - "$output_path" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    data = json.load(f)
summary = data["summary"]
if summary["drifted"] <= 0:
    print(summary)
    sys.exit(1)
PY
}

mutate_rfc3492() {
  target_root=$1
  mkdir -p "$target_root/typescript/src"
  cp "$repo_root/fixtures/project/spec-align-rfc3492/typescript/package.json" \
    "$target_root/typescript/package.json"
  python3 - "$repo_root/fixtures/project/spec-align-rfc3492/typescript/src/punycode.ts" \
    "$target_root/typescript/src/punycode.ts" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
mutated = source.replace("const base = 36", "const base = 35", 1)
pathlib.Path(sys.argv[2]).write_text(mutated)
PY
  printf '%s\n' "$target_root/typescript"
}

mutate_rfc2795() {
  target_root=$1
  mkdir -p "$target_root/typescript/src"
  cp "$repo_root/fixtures/project/spec-align-rfc2795/typescript/package.json" \
    "$target_root/typescript/package.json"
  python3 - "$repo_root/fixtures/project/spec-align-rfc2795/typescript/src/keeper.ts" \
    "$target_root/typescript/src/keeper.ts" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
mutated = source.replace("const REQUEST_STOP = 7", "const REQUEST_STOP = 8", 1)
pathlib.Path(sys.argv[2]).write_text(mutated)
PY
  printf '%s\n' "$target_root/typescript"
}

run_case() {
  name=$1
  threshold=$2
  source_path=$3
  impl_path=$4
  mutate_fn=$5

  case_root="$work_root/$name/$threshold"
  mkdir -p "$case_root"
  draft_path="$case_root/draft.md"
  baseline_cache="$case_root/cache-baseline"
  baseline_status="$case_root/status-baseline.json"
  mutated_root="$case_root/mutated"
  mutated_cache="$case_root/cache-mutated"
  mutated_status="$case_root/status-mutated.json"

  run_draft "$source_path" "$draft_path"
  run_status_json "$threshold" "$draft_path" "$impl_path" "$baseline_cache" "$baseline_status"
  assert_zero_drift "$baseline_status"

  mutated_impl=$($mutate_fn "$mutated_root")
  assert_detects_drift "$threshold" "$draft_path" "$mutated_impl" "$mutated_cache" "$mutated_status"

  python3 - "$name" "$threshold" "$baseline_status" "$mutated_status" <<'PY'
import json
import sys

name, threshold, baseline_path, mutated_path = sys.argv[1:5]
with open(baseline_path) as f:
    baseline = json.load(f)["summary"]
with open(mutated_path) as f:
    mutated = json.load(f)["summary"]
print(
    f"{name}\t{threshold}\t"
    f"baseline matched={baseline['matched']} drifted={baseline['drifted']} spec_only={baseline['spec_only']} impl_only={baseline['impl_only']}\t"
    f"mutated matched={mutated['matched']} drifted={mutated['drifted']} spec_only={mutated['spec_only']} impl_only={mutated['impl_only']}"
)
PY
}

printf '%s\n' "name\tthreshold\tbaseline\tmutated"
for threshold in $thresholds; do
  run_case \
    "rfc3492" \
    "$threshold" \
    "fixtures/project/spec-align-rfc3492/spec/rfc3492.rfc.txt" \
    "fixtures/project/spec-align-rfc3492/typescript" \
    mutate_rfc3492
  run_case \
    "rfc2795" \
    "$threshold" \
    "fixtures/project/spec-align-rfc2795/spec/rfc2795.rfc.txt" \
    "fixtures/project/spec-align-rfc2795/typescript" \
    mutate_rfc2795
done
