#!/usr/bin/env sh
set -eu

repo_root=$(
  CDPATH= cd -- "$(dirname "$0")/.." && pwd
)

source_path=${1:-cmd/indexion/spec/align/README.md}
impl_path=${2:-cmd/indexion/spec}
work_dir=${3:-"$repo_root/.indexion/state/dogfood/spec-align"}
threshold=${4:-0.05}

mkdir -p "$work_dir"
spec_path="$work_dir/draft.md"
cache_dir="$work_dir/cache"
diff_path="$work_dir/diff.md"
trace_path="$work_dir/trace.json"
suggest_path="$work_dir/suggest.md"
tasks_generic_path="$work_dir/tasks-generic.md"
tasks_claude_path="$work_dir/tasks-claude.md"
tasks_copilot_path="$work_dir/tasks-copilot.md"
delta_spec_path="$work_dir/delta-spec.md"
loop_path="$work_dir/loop.md"
status_text_path="$work_dir/status.txt"
status_json_path="$work_dir/status.json"

cd "$repo_root"

./scripts/indexion-native.sh spec draft \
  --specs-dir=kgfs \
  --output="$spec_path" \
  "$source_path"

./scripts/indexion-native.sh spec align diff \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --format=markdown \
  "$spec_path" \
  "$impl_path" \
  > "$diff_path"

./scripts/indexion-native.sh spec align trace \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --format=json \
  "$spec_path" \
  "$impl_path" \
  > "$trace_path"

./scripts/indexion-native.sh spec align suggest \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --direction=both \
  --format=markdown \
  "$spec_path" \
  "$impl_path" \
  > "$suggest_path"

./scripts/indexion-native.sh spec align suggest \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --direction=both \
  --format=tasks \
  --agent=generic \
  "$spec_path" \
  "$impl_path" \
  > "$tasks_generic_path"

./scripts/indexion-native.sh spec align suggest \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --direction=both \
  --format=tasks \
  --agent=claude \
  "$spec_path" \
  "$impl_path" \
  > "$tasks_claude_path"

./scripts/indexion-native.sh spec align suggest \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --direction=both \
  --format=tasks \
  --agent=copilot \
  "$spec_path" \
  "$impl_path" \
  > "$tasks_copilot_path"

./scripts/indexion-native.sh spec align suggest \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --direction=impl-wins \
  --format=delta-spec \
  "$spec_path" \
  "$impl_path" \
  > "$delta_spec_path"

./scripts/indexion-native.sh spec align status \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --fail-on=none \
  --format=json \
  "$spec_path" \
  "$impl_path" \
  > "$status_json_path"

./scripts/indexion-native.sh spec align status \
  --specs-dir=kgfs \
  --cache-dir="$cache_dir" \
  --threshold="$threshold" \
  --fail-on=none \
  --format=text \
  "$spec_path" \
  "$impl_path" \
  > "$status_text_path"

[ -s "$spec_path" ]
[ -s "$diff_path" ]
[ -s "$trace_path" ]
[ -s "$suggest_path" ]
[ -s "$tasks_generic_path" ]
[ -s "$tasks_claude_path" ]
[ -s "$tasks_copilot_path" ]
[ -s "$delta_spec_path" ]
[ -s "$status_json_path" ]
[ -s "$status_text_path" ]
rg -q '"matched":\s*[1-9]' "$status_json_path"
rg -q '"total_requirements":\s*[1-9]' "$status_json_path"
rg -q '"edges":\s*\[' "$trace_path"
rg -q '^# (Spec Align Tasks|Claude Tasks|Copilot Tasks)' "$tasks_generic_path"
rg -q '^# (Spec Align Tasks|Claude Tasks|Copilot Tasks)' "$tasks_claude_path"
rg -q '^# (Spec Align Tasks|Claude Tasks|Copilot Tasks)' "$tasks_copilot_path"

{
  printf '# Spec Align Dogfood Loop\n\n'
  printf '%s\n' "- Source: \`$source_path\`"
  printf '%s\n' "- Impl: \`$impl_path\`"
  printf '%s\n' "- Draft: \`$spec_path\`"
  printf '%s\n' "- Threshold: \`$threshold\`"
  printf '\n## Status\n\n'
  cat "$status_text_path"
  printf '\n## Outputs\n\n'
  printf '%s\n' "- Diff: \`$diff_path\`"
  printf '%s\n' "- Trace: \`$trace_path\`"
  printf '%s\n' "- Suggest: \`$suggest_path\`"
  printf '%s\n' "- Generic Tasks: \`$tasks_generic_path\`"
  printf '%s\n' "- Claude Tasks: \`$tasks_claude_path\`"
  printf '%s\n' "- Copilot Tasks: \`$tasks_copilot_path\`"
  printf '%s\n' "- Delta Spec: \`$delta_spec_path\`"
  printf '\n## Next Step\n\n'
  printf '1. Inspect `%s` to see the drafted SDD.\n' "$spec_path"
  printf '2. Use `%s` or `%s` as the agent handoff.\n' "$tasks_claude_path" "$tasks_copilot_path"
  printf '3. Apply the highest-signal fixes from `%s`.\n' "$suggest_path"
  printf '4. Re-run `./scripts/spec-align-dogfood.sh %s %s %s %s` until the summary stabilizes.\n' "$source_path" "$impl_path" "$work_dir" "$threshold"
} > "$loop_path"

[ -s "$loop_path" ]

printf '%s\n' "dogfood draft: $spec_path"
printf '%s\n' "dogfood diff:  $diff_path"
printf '%s\n' "dogfood trace: $trace_path"
printf '%s\n' "dogfood suggest:$suggest_path"
printf '%s\n' "dogfood status: $status_text_path"
printf '%s\n' "dogfood loop:  $loop_path"
