#!/usr/bin/env bash
set -euo pipefail

REF="${1:-HEAD}"

if ! git rev-parse --verify "${REF}^{commit}" >/dev/null 2>&1; then
  echo "error: invalid ref '${REF}'" >&2
  exit 1
fi

mapfile -t files < <(git ls-tree -r --name-only "${REF}" | grep -v '^\.git' || true)
total="${#files[@]}"
over1k=0
todos=0
declare -A line_counts

while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  lines="$(git show "${REF}:${f}" 2>/dev/null | wc -l | tr -d ' ')" || lines=0
  line_counts["${f}"]="${lines}"
  (( lines > 1000 )) && ((over1k++)) || true
  if git show "${REF}:${f}" 2>/dev/null | grep -qiE '\b(TODO|FIXME)\b'; then
    ((todos++)) || true
  fi
done < <(printf '%s\n' "${files[@]}")

# Top 20 by lines
sorted=()
while IFS= read -r entry; do
  sorted+=("${entry}")
done < <(
  for f in "${!line_counts[@]}"; do
    printf '%s\t%s\n' "${line_counts[$f]}" "${f}"
  done | sort -rn | head -20
)

files_json="["
first=1
for entry in "${sorted[@]}"; do
  lines="${entry%%$'\t'*}"
  path="${entry#*$'\t'}"
  [[ "${first}" -eq 1 ]] && first=0 || files_json+=","
  files_json+=$(jq -n --arg p "${path}" --argjson l "${lines}" '{path:$p,lines:$l}')
done
files_json+="]"

jq -n \
  --argjson totalFiles "${total}" \
  --argjson filesOver1000 "${over1k}" \
  --argjson todos "${todos}" \
  --argjson files "${files_json}" \
  '{
    summary: {
      totalFiles: $totalFiles,
      filesOver1000: $filesOver1000,
      todos: $todos,
      godClasses: 0,
      avgCyclomaticComplexity: 0
    },
    files: $files
  }'
