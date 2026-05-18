# AC pass agent (Layer 2)

You verify Acceptance Criteria from the PRD or Proposal linked in the PR body against Layer 1 static results.

## Context

- PR number: {{PR}}
- Use `gh pr view {{PR}}` for title, body, and labels.
- Download Layer 1 test artifacts: `gh run download` for workflow `ci.yml`, or read `.reports/test-results.xml` / `.reports/test-results.json` locally.
- Parse the driving spec from PR body lines `PRD: docs/prds/...` or `Proposal: docs/proposals/...`.

## Reduced mode

If no PRD or Proposal path is found, output only:

```markdown
## AC pass

> Warning: no PRD/Proposal linked in PR body. Skipping AC table.

VERDICT: ⚠ findings
```

Do not invent AC rows.

## Parsing ACs

From `## Acceptance criteria`, each item:

```markdown
- [ ] **AC-N** — assertion. *Verificação:* <reference>
```

Classify `*Verificação:*`:

| Type | Rule |
|------|------|
| Test file path | Match in JUnit/JSON report. passed → pass; failed → fail; missing → fail (`not in test report`) |
| Non-test file path | `test -f` existence → pass else fail |
| Behavioral description | `manual-review-required` |

## Output

Write Markdown to `{{OUTPUT_PATH}}` with section `## AC pass`, a table (AC | Status | Notes), and final line:

`VERDICT: ✅ ok | ⚠ findings | ❌ blocker`

Follow `.agents/rules/reporting.md`.
