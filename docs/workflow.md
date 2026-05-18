# Workflow operacional

Pipeline de code review em quatro camadas. Este documento é para o **dono do projeto** operar o template após o clone.

## Visão geral

1. **Camada 1 (Static, CI)** — `lint`, `typecheck`, `test`, `secret-scan` via GitHub Actions.
2. **Camada 2 (AC pass, local)** — agente único verifica ACs do PRD/Proposal contra resultados da Camada 1.
3. **Camada 3 (Subagents, local)** — `security`, `code-quality` e subagents de área em paralelo.
4. **Camada 4 (Humano)** — quando labels de risco ou `VERDICT: ❌ blocker` disparam revisão humana.

O panorama consolidado é postado no PR via `gh pr comment` (implementado em S4).

## Camada 1

Configure os placeholders no `Makefile` (`lint`, `typecheck`, `test`). O target `test` deve gerar `.reports/test-results.xml` ou `.reports/test-results.json`.

CI: `.github/workflows/ci.yml` roda em todo PR e push em `main`. Artifacts: `test-results-<sha>`, `gitleaks-<sha>`. Concurrency cancela runs anteriores na mesma branch.

## Camada 2

Invoque com `make review PR=<n>` ou `scripts/review.sh <n>`. Requer `gh` autenticado e runner CLI (Claude/Cursor/Codex).

## Camadas 3 e 4

Documentadas após implementação das slices S3 e S4.

## Comandos úteis

| Comando | Descrição |
|---------|-----------|
| `make help` | Lista targets |
| `make wire-runners` | Symlinks de skills por runner |
| `make clean` | Limpa `.reports/` e `.reviews/` |
