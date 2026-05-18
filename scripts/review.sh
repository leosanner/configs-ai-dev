#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/review-common.sh
source "${ROOT}/scripts/lib/review-common.sh"

RUNNER="claude"
PR=""
DRY_RUN="${WORKFLOW_SETUP_DRY_RUN:-0}"

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

AC_OUT="$(run_ac_pass "${PR}" "${RUNNER}" "${REVIEWS_DIR}")"

# Camada 3 — Subagents (S4 implementa)
# TODO(S4): launch core subagents + area subagents in parallel, wait, aggregate.
# Por enquanto: copy AC pass como panorama provisório.
PANORAMA="${REVIEWS_DIR}/${PR}-${TS}-panorama.md"
{
  echo '<!-- workflow-setup:review -->'
  cat "${AC_OUT}"
} >"${PANORAMA}"

# Posting do panorama (S4 implementa)
# TODO(S4): gh pr comment --edit-last com marker HTML
echo "${PANORAMA}"
