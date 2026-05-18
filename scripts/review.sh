#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/review-common.sh
source "${ROOT}/scripts/lib/review-common.sh"

RUNNER="claude"
PR=""
DRY_RUN="${WORKFLOW_SETUP_DRY_RUN:-0}"
SUBAGENT_TIMEOUT="${SUBAGENT_TIMEOUT:-300}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with) RUNNER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *)
      if [[ -z "${PR}" ]]; then PR="$1"; shift; else echo "unknown arg: $1" >&2; exit 1; fi
      ;;
  esac
done

resolve_pr
mkdir -p "${REVIEWS_DIR}"
TS="$(timestamp)"
fetch_test_report

run_ac_pass() {
  local pr="$1" runner="$2" reviews_dir="$3"
  RUNNER="${runner}"
  local out="${reviews_dir}/${pr}-${TS}-ac-pass.md"
  invoke_runner "AC pass" "${AGENTS_DIR}/prompts/ac-pass.md" "${out}"
  echo "${out}"
}

run_subagent() {
  local name="$1" out="$2"
  if timeout "${SUBAGENT_TIMEOUT}" bash -c "
    source '${ROOT}/scripts/lib/review-common.sh'
    PR='${PR}'; RUNNER='${RUNNER}'; DRY_RUN='${DRY_RUN}'
    invoke_runner '${name}' '${AGENTS_DIR}/prompts/${name}.md' '${out}'
  "; then
    return 0
  fi
  printf '## %s\n\nmanual-review-required (timeout or runner failure)\n\nVERDICT: ⚠ findings\n' "${name}" >"${out}"
}

launch_layer3() {
  local -a pids=() names=() outs=()
  names=(security code-quality)
  has_label area:auth && names+=(auth)
  has_label area:db && names+=(db)
  has_label area:architecture && names+=(architecture)

  for n in "${names[@]}"; do
    local o="${REVIEWS_DIR}/${PR}-${TS}-${n}.md"
    outs+=("${o}")
    run_subagent "${n}" "${o}" &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "${pid}" || true; done
  printf '%s\n' "${outs[@]}"
}

AC_OUT="$(run_ac_pass "${PR}" "${RUNNER}" "${REVIEWS_DIR}")"
mapfile -t SUB_OUTS < <(launch_layer3)

PANORAMA="${REVIEWS_DIR}/${PR}-${TS}-panorama.md"
GLOBAL="✅ ok"
HUMAN_LINE=""
if mapfile -t triggers < <(human_review_triggers); ((${#triggers[@]})); then
  HUMAN_LINE="Human review required: yes (gatilho: ${triggers[*]})"
fi

{
  echo '<!-- workflow-setup:review -->'
  echo "## Global verdict"
  [[ -n "${HUMAN_LINE}" ]] && echo "${HUMAN_LINE}"
  echo
  cat "${AC_OUT}"
  echo
  for f in "${SUB_OUTS[@]}"; do
    echo "---"
    cat "${f}"
    echo
    grep -q 'VERDICT: ❌ blocker' "${f}" && GLOBAL="❌ blocker"
    grep -q 'VERDICT: ⚠ findings' "${f}" && [[ "${GLOBAL}" != "❌ blocker" ]] && GLOBAL="⚠ findings"
  done
  echo "**Overall:** ${GLOBAL}"
} >"${PANORAMA}"

if [[ "${DRY_RUN}" != "1" ]] && command -v gh >/dev/null 2>&1; then
  if gh pr comment "${PR}" --edit-last --body-file "${PANORAMA}" 2>/dev/null; then
    :
  else
    gh pr comment "${PR}" --body-file "${PANORAMA}" || true
  fi
fi

echo "${PANORAMA}"
