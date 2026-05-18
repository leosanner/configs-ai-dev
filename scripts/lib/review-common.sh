#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REVIEWS_DIR="${ROOT}/.reviews"
REPORTS_DIR="${ROOT}/.reports"
AGENTS_DIR="${ROOT}/.agents"

usage() {
  cat <<'EOF'
Usage: scripts/review.sh [<PR>] [--with claude|cursor|codex] [--dry-run]
EOF
}

resolve_pr() {
  if [[ -n "${PR:-}" ]]; then return 0; fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh CLI required; pass <PR> explicitly" >&2
    exit 1
  fi
  PR="$(gh pr view --json number -q .number 2>/dev/null || true)"
  if [[ -z "${PR}" ]]; then
    echo "error: no open PR for current branch — pass <PR> explicitly" >&2
    exit 1
  fi
}

timestamp() { date -u +%Y%m%dT%H%M%SZ; }

fetch_test_report() {
  mkdir -p "${REPORTS_DIR}"
  if [[ -f "${REPORTS_DIR}/test-results.xml" || -f "${REPORTS_DIR}/test-results.json" ]]; then
    return 0
  fi
  command -v gh >/dev/null 2>&1 || return 0
  local run_id
  run_id="$(gh run list --workflow=ci.yml --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
  [[ -n "${run_id}" ]] && gh run download "${run_id}" -D "${REPORTS_DIR}/_ci" 2>/dev/null || true
  find "${REPORTS_DIR}/_ci" -name 'test-results.*' -exec cp -n {} "${REPORTS_DIR}/" \; 2>/dev/null || true
}

pr_labels() {
  gh pr view "${PR}" --json labels -q '.labels[].name' 2>/dev/null || true
}

has_label() {
  local want="$1"
  pr_labels | grep -qx "${want}"
}

human_review_triggers() {
  local l
  for l in area:auth area:secrets area:migrations area:public-read risk:high; do
    has_label "${l}" && echo "${l}"
  done
}

invoke_runner() {
  local _name="$1" prompt_path="$2" output_path="$3"
  local prompt
  prompt="$(cat "${prompt_path}")"
  prompt="${prompt//\{\{PR\}\}/${PR}}"
  prompt="${prompt//\{\{OUTPUT_PATH\}\}/${output_path}}"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    if [[ "${_name}" == "AC pass" ]]; then
      printf '## AC pass\n\n| AC | Status | Notes |\n|----|--------|-------|\n| AC-1 | pass | dry-run |\n\nVERDICT: ✅ ok\n' >"${output_path}"
    else
      printf '## %s\n\n(dry-run)\n\nVERDICT: ✅ ok\n' "${_name}" >"${output_path}"
    fi
    return 0
  fi

  case "${RUNNER}" in
    claude)
      command -v claude >/dev/null 2>&1 || { echo "error: claude not in PATH" >&2; exit 1; }
      claude --print "${prompt}" >"${output_path}"
      ;;
    cursor)
      command -v cursor-agent >/dev/null 2>&1 || { echo "error: cursor-agent not in PATH" >&2; exit 1; }
      cursor-agent -p "${prompt}" >"${output_path}"
      ;;
    codex)
      command -v codex >/dev/null 2>&1 || { echo "error: codex not in PATH" >&2; exit 1; }
      codex exec -C "${ROOT}" "${prompt}" >"${output_path}"
      ;;
    *) echo "error: unknown runner ${RUNNER}" >&2; exit 1 ;;
  esac
}
