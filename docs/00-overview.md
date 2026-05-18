# 00 — Visão geral

> Status: **active**. Documento de entrada do planejamento. Lê-se em ~5 minutos.

## O que este repositório é

`workflow-setup` é um **template de GitHub** para uma **pipeline de code review em 4 camadas**, projetada para:

- Rodar **localmente** durante desenvolvimento (zero custo extra, usa a assinatura existente de Claude/Cursor/Codex).
- Ser **agnóstica de stack** — o template não assume Node, Python, Go ou Rust.
- Funcionar com **qualquer um dos três runners** (Claude, Cursor, Codex), escolhido por flag `--with <runner>`.
- Postar um **panorama consolidado** no GitHub PR ao final, via `gh pr comment`.

O destinatário é um único humano (o dono) que clica "Use this template" no GitHub, customiza um Makefile com os comandos da sua stack, e ganha pipeline operacional em minutos.

## Audiência

| Quem | Para quê |
|---|---|
| **Dono do projeto-cliente** (o usuário primário) | Clona via "Use this template", preenche Makefile, opera a pipeline em todo PR. |
| **Agente de IA executando uma slice** | Lê estes docs para entender contexto e contrato antes de escrever código. Não precisa do histórico da conversa que gerou esta documentação. |
| **Futuro contribuidor humano** | Entende o porquê de cada decisão sem ter participado da sessão original. |

## Princípios destilados

Decisões enraizadas no design. Quebrá-las quebra a coerência interna do template.

1. **Determinístico antes de probabilístico.** Camada 1 (lint/test/secret-scan) gateia o gasto de LLM. PR que não passa no static não desperdiça contexto de agente.
2. **Resultado consultado, não re-executado.** A Camada 2 (AC pass) lê o resultado da Camada 1 — não roda testes de novo. Cada teste roda uma vez por commit.
3. **Subagent paralelo por categoria.** Camada 3 não é "um agente que olha tudo" — é **N agentes especialistas em paralelo**, cada um com prompt focado. Mais sinal, menos contexto desperdiçado por subagent.
4. **Core sempre, específico por label.** `security` e `code-quality` rodam em todo PR (sempre). `auth`, `db`, `architecture` só rodam se o label `area:*` correspondente estiver presente.
5. **Humano é último gate, condicional.** Não é "humano sempre", nem "nunca". Dispara quando há **label de risco** (`area:auth`, `area:secrets`, etc.) ou **algum subagent emite blocker**. CODEOWNERS + branch protection fazem o bloqueio efetivo.
6. **Stack vive no Makefile.** O template não assume linguagem. `make lint`, `make typecheck`, `make test` são placeholders preenchidos pelo dono. A pipeline chama `make` sem saber o que tem por baixo.
7. **`.agents/` é fonte única.** Prompts, skills e rules vivem em `.agents/`. Wrappers em `.claude/`, `.cursor/`, `.codex/` são opt-in via `make wire-runners` (symlinks). Tudo o que importa está em um lugar.
8. **`docs/` é para humanos, `.agents/` é para agentes.** Sem mistura. Convenções de código vivem em `docs/conventions.md`; o subagent `code-quality` lê de lá. Mas o prompt do `code-quality` vive em `.agents/prompts/code-quality.md`.
9. **Acceptance Criteria é o contrato.** Todo PRD/Proposal carrega ACs numerados (`AC-N`) com `*Verificação:*` apontando para artefato concreto. O AC pass valida 1-a-1. ACs são estáveis (não-renumeráveis).
10. **Panorama é um comment único, sobrescrevível.** Re-run do `scripts/review.sh` substitui o comment anterior do mesmo PR via marker HTML. Uma fonte canônica por PR, sem ruído de histórico.

## Pipeline em 4 camadas (vista de pássaro)

```
                       ┌─────────────────────────────────────┐
                       │  Camada 1 — Static (CI)            │
                       │  make lint · typecheck · test      │
   Code pushed  ─────▶ │  + gitleaks secret-scan            │
                       │  Falhou? → para. Não chama LLM.    │
                       └──────────────┬──────────────────────┘
                                      │ ok
                       ┌──────────────▼──────────────────────┐
                       │  Camada 2 — AC pass (local, agente)│
                       │  Lê o PRD/Proposal do PR body.     │
                       │  Consulta JUnit/test-output da     │
                       │  Camada 1. Marca cada AC pass/fail.│
                       └──────────────┬──────────────────────┘
                                      │ ok ou findings
            ┌─────────────────────────┼─────────────────────────┐
            │  Camada 3 — Subagents (local, paralelo)            │
            │  ┌─────────────┐  ┌────────────────┐               │
            │  │ security    │  │ code-quality   │   sempre rodam│
            │  └─────────────┘  └────────────────┘               │
            │  ┌─────────────┐  ┌─────┐  ┌──────────────┐        │
            │  │ auth        │  │ db  │  │ architecture │ por    │
            │  └─────────────┘  └─────┘  └──────────────┘ label  │
            └────────────────────────┬───────────────────────────┘
                                     │ todos retornam
                       ┌─────────────▼───────────────────────┐
                       │  Agregação                          │
                       │  Consolida AC + subagents.          │
                       │  Decide veredito.                   │
                       │  Detecta gatilhos de Camada 4.      │
                       └──────────────┬──────────────────────┘
                                      │
                       ┌──────────────▼──────────────────────┐
                       │  gh pr comment <PR> --body-file ... │
                       │  Comment sobrescrito via marker.    │
                       └──────────────┬──────────────────────┘
                                      │
                       ┌──────────────▼──────────────────────┐
                       │  Camada 4 — Human review            │
                       │  Disparo: label de risco            │
                       │           OU subagent blocker.      │
                       │  Mecanismo: CODEOWNERS + protection.│
                       └─────────────────────────────────────┘
```

Detalhe técnico de cada camada vive em `01-architecture.md`.

## Mapa de leitura por intenção

| Quero… | Leia… |
|---|---|
| Entender a arquitetura no detalhe | [`01-architecture.md`](./01-architecture.md) |
| Saber **por que** cada coisa é assim | [`02-decisions.md`](./02-decisions.md) |
| Saber onde cada arquivo do template vai morar | [`03-target-structure.md`](./03-target-structure.md) |
| Executar uma slice (sou um agente / dev) | [`04-slices.md`](./04-slices.md) |
| Saber o que ficou aberto / TODO | [`05-open-questions.md`](./05-open-questions.md) |
| Lookup rápido de termos | [`06-glossary.md`](./06-glossary.md) |
| Disparar sessões paralelas S3/S4 sem se atropelar | [`07-parallel-execution.md`](./07-parallel-execution.md) |

## O que NÃO está neste template (v1)

Explicitado para travar escopo:

- **SAST profundo** (Semgrep com regras customizadas). Security fica como subagent LLM apenas.
- **Coverage threshold** como check. Pode entrar como upgrade.
- **Dependency review / CVE check**. Idem.
- **License check.** Idem.
- **Subagents** para `area:performance`, `area:ux`, `area:public-read`. Listados como exemplos em `docs/labels.md`, mas sem prompt implementado.
- **General-conventions subagent dedicado.** A função é absorvida pelo `code-quality` core (lê `docs/conventions.md` como base).
- **CI ativo em `.github/workflows/` ligado por default.** Os arquivos podem ser entregues comentados/desligados; o dono liga quando quiser. Decisão na slice S2.
- **Histórico persistente de métricas** além do `git log` do `docs/quality.md`.
- **Auto-merge.** Humano sempre confirma o último clique, mesmo quando veredito é `✅ ready to merge`.

## Status dos artefatos

| Artefato | Status |
|---|---|
| Decisões de design | ✅ travadas (sessão `/grill-me`, ver `02-decisions.md`) |
| Planning docs | 🔧 em escrita (você está lendo) |
| `README.md` raiz | ✅ reescrito do zero |
| `Makefile` com placeholders | ⏳ S1 |
| `scripts/review.sh` (orquestrador) | ⏳ S3 (stub em S1) |
| `scripts/quality-scan.sh` | ⏳ S4 (consumido pelo `code-quality` subagent) |
| `.agents/prompts/<name>.md` | ⏳ S3/S4 |
| Wrappers `.agents/skills/<runner>/<name>/` | ⏳ S4 |
| `.github/workflows/ci.yml` | ⏳ S2 |
| `CODEOWNERS` exemplo | ⏳ S2 ou S3 |
| Templates de PRD / Proposal / ADR | ⏳ S1 |
| `docs/conventions.md`, `docs/workflow.md`, `docs/labels.md` (do template, não destes planning docs) | ⏳ S1 |
