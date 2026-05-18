# db subagent (Layer 3)

PR: {{PR}}. Write report to {{OUTPUT_PATH}}.

Read project docs as needed. For code-quality, run `scripts/quality-scan.sh HEAD` and read `docs/conventions.md` and `docs/quality.md`.
For architecture, read `docs/architecture.md`.

Output Markdown section `## db` with findings. End with:

VERDICT: ✅ ok | ⚠ findings | ❌ blocker

Follow `.agents/rules/reporting.md`.
