# 05 — Perguntas em aberto

> Status: **active**. Pendências deferidas conscientemente. Cada entrada tem **dono temporal** (em qual slice deve ser fechada), uma **recomendação atual**, e o **risco** de não fechar.

Formato: `OQ-N — Pergunta`, contexto, recomendação atual, dono (slice), risco. Ao fechar, transferir para `02-decisions.md` como `D-NN`.

## OQ-1 — Comando exato do Cursor CLI para invocação não-interativa

**Contexto:** o template promete `--with cursor` no `scripts/review.sh`. A CLI do Cursor (`cursor-agent`?) precisa aceitar:
- Prompt via argumento ou stdin.
- Modo não-interativo (sem abrir UI).
- Output em stdout ou em arquivo de saída.
- Bypass de permissões (equivalente ao `--permission-mode bypassPermissions` do Claude e `--dangerously-bypass-approvals-and-sandbox` do Codex).

**Recomendação atual:** investigar em 5 minutos de `cursor-agent --help` antes de começar S3. Se a CLI não suportar invocação não-interativa, ou (a) reduzir support a Claude+Codex no v1 com nota em `docs/workflow.md`, ou (b) usar SDK programático se disponível.

**Dono:** S3.

**Risco:** baixo. Se Cursor não funcionar bem, removemos do v1; usuário invoca via interface do IDE quando precisar.

## OQ-2 — Comando exato do Codex CLI

**Contexto:** mesma pergunta, para `codex exec`. O comando-base hoje é `codex exec --dangerously-bypass-approvals-and-sandbox -C <dir> "<prompt>"`. Confirmar:
- Como passar o output path (Codex já entende `Write the report to: <path>` no prompt?).
- Se há flag para tempo limite.
- Comportamento quando o repo não é confiável.

**Recomendação atual:** investigar em 5 minutos antes de S3.

**Dono:** S3.

**Risco:** baixo.

## OQ-3 — Timeout por subagent

**Contexto:** Camada 3 roda subagents em paralelo. Um subagent que trava em loop pode reter o `wait` do orquestrador indefinidamente.

**Recomendação atual:** `timeout 300 <comando>` (5 minutos por subagent) com fallback claro: subagent abortado → seção do panorama marcada `manual-review-required` + razão "timeout exceeded".

**Dono:** S4.

**Risco:** médio. Sem timeout, um subagent travado bloqueia o panorama. Implementação é trivial (uma flag no `timeout`).

## OQ-4 — Threshold de "Quality piora" para gatilho de Camada 4

**Contexto:** rejeitamos Q9-d ("delta de Quality piora") como gatilho de Camada 4 nas decisões iniciais. Pode reintroduzir quando as métricas avançadas (godClasses, complexity, etc.) estiverem implementadas.

**Recomendação atual:** **adiar.** v1 não usa Quality como gatilho. Quando as métricas reais entrarem (pós-v1), reintroduzir como `D-25`.

**Dono:** pós-v1.

**Risco:** zero no v1.

## OQ-5 — Política de retry em runner que falha

**Contexto:** runner crasha (Claude API down, Codex auth expirou, etc.). Subagent não retorna `VERDICT:`.

**Recomendação atual:** **sem retry automático.** Subagent que falha → `manual-review-required`. Operador re-roda `scripts/review.sh` quando o runner voltar. Mantém previsibilidade de custo.

**Dono:** S4.

**Risco:** baixo. Re-run completo é barato em comparação a inventar lógica de retry parcial.

## OQ-6 — Detecção de PR aberto no `scripts/review.sh` sem flag `<PR>`

**Contexto:** `scripts/review.sh` deve aceitar `<PR>` ou pegar do branch atual via `gh pr view --json number`. Funciona em fluxo normal; falha quando:
- Branch ainda não tem PR aberto.
- Múltiplos PRs no mesmo branch (raro).
- Branch é `main`.

**Recomendação atual:** se `gh pr view` retorna vazio, falhar com mensagem "no open PR for current branch — pass <PR> explicitly". Documentar em `--help`.

**Dono:** S3.

**Risco:** baixo. UX, não correctness.

## OQ-7 — Caso o `Write` (`--edit-last`) do `gh pr comment` não estar disponível

**Contexto:** `gh pr comment --edit-last` é flag relativamente recente. Em versões antigas do `gh`, precisamos descobrir o ID do comment via marker HTML e fazer `gh api`.

**Recomendação atual:** detectar versão do `gh` no início do `scripts/review.sh`. Se `--edit-last` não disponível, fallback para `gh api /repos/.../issues/<n>/comments` para buscar comments, achar o que tem o marker `<!-- workflow-setup:review -->` e usar `PATCH` para sobrescrever.

**Dono:** S4.

**Risco:** médio. Sem fallback, re-runs criam N comments e poluem o PR.

## OQ-8 — Onde mora o snapshot do `docs/quality.md` no primeiro run

**Contexto:** `code-quality` subagent compara delta vs `docs/quality.md`. No primeiro run, `quality.md` está vazio (seed state).

**Recomendação atual:** seed state = tabela com células vazias. Subagent detecta, omite seção de delta, mostra só "snapshot atual". `docs/quality.md` é populado depois do primeiro merge aprovado (manual, via PR seguinte que copia o `quality-proposal.md`).

**Dono:** S4.

**Risco:** baixo. Caso de uso explícito no prompt.

## OQ-9 — Suporte a múltiplos PRDs ou Proposals num único PR

**Contexto:** PR raramente, mas pode, fechar duas Proposals. Body teria duas linhas `Proposal:`.

**Recomendação atual:** v1 assume **um** PRD ou Proposal por PR. Se body tiver mais de um, usar o primeiro e emitir warning no panorama.

**Dono:** S3.

**Risco:** baixo. Caso raro.

## OQ-10 — Comportamento quando `make test` não roda em CI mas no local

**Contexto:** AC pass tenta ler `.reports/test-results.*`. Se o dev rodou `scripts/review.sh` local antes do CI completar, o artifact pode não existir.

**Recomendação atual:** AC pass detecta ausência → emite warning "test results not available; AC pass needs CI completion" e marca todos ACs que dependem de testes como `manual-review-required`. Documentar em `docs/workflow.md` que CI precisa terminar antes do review local.

**Dono:** S3.

**Risco:** médio. Sem isso, AC pass dá falso negativo em runs prematuros.

## OQ-11 — Inclusão de `area:performance`, `area:ux`, `area:public-read` como subagents

**Contexto:** decidido em D-13 deixar de fora do v1. Listados em `docs/labels.md` como exemplos.

**Recomendação atual:** manter fora. Adicionar quando o uso real demandar. Cada nova área é um par `(prompt em .agents/prompts/, label em docs/labels.md, condicional em scripts/review.sh)` — incremental sem regressão.

**Dono:** pós-v1.

**Risco:** zero.

## OQ-12 — General-conventions subagent dedicado

**Contexto:** decidido em D-13 absorver pelo `code-quality`. Se o `code-quality` ficar enciclopédico demais, separar.

**Recomendação atual:** monitorar tamanho de `.agents/prompts/code-quality.md` durante S4. Se passar de ~300 linhas, considerar split.

**Dono:** S4 (monitor) / pós-v1 (eventual split).

**Risco:** baixo. Prompts são fáceis de refatorar.

## OQ-13 — Idioma dos prompts dos subagents

**Contexto:** D-24 diz EN para "prompts de agentes". Confirmação: PRDs/Proposals que o agente lê são em PT-BR ou EN no template?

**Recomendação atual:** templates `_template.md` em EN (campos `## Problem`, `## Goal`, `## Acceptance criteria` etc.) por consistência com prompts. **Texto que o dono preenche pode ser PT-BR** — agentes modernos lidam bem com mistura. ACs específicas como `*Verificação:*` (sub-heading em PT-BR) já são reconhecidas pelo prompt do `ac-pass`.

**Dono:** S1 (templates) / S3 (prompt).

**Risco:** baixo.

## OQ-14 — Como atualizar o template depois do v1

**Contexto:** GitHub template repo não propaga updates. Quando o template evoluir (v1.1, v2), projetos-cliente precisam de processo de re-sync.

**Recomendação atual:** v1 não resolve. Documentar em README a opção `git remote add template <url>` + `git fetch template main` + cherry-pick manual quando o dono quiser puxar updates.

**Dono:** pós-v1.

**Risco:** zero no v1. Dor real quando v1 estiver em uso em 3+ projetos.

## OQ-15 — Custo agregado de uma execução completa

**Contexto:** 1 AC pass + 2 core + até 3 area = 3 a 6 chamadas LLM por PR. Sem medição, podemos descobrir tarde que o custo médio é desconfortável.

**Recomendação atual:** durante uso real pós-v1, anotar tempo wallclock e tokens (quando o runner expõe). Sem dashboard formal — informal em `docs/quality.md` ou notes.

**Dono:** pós-v1.

**Risco:** médio. Mitigado pela assinatura do usuário cobrir o uso e pela arquitetura em cascata (Camada 1 filtra).
