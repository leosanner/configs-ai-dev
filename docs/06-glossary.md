# 06 — Glossário

> Status: **active**. Definições curtas dos termos usados em toda a documentação. Cada entrada aponta para a referência canônica.

## A

**Acceptance Criteria (AC).** Asserção atômica e testável que define o contrato entre escopo (PRD/Proposal) e merge. Cada AC tem ID estável (`AC-N` ou `AC-S<slice>-N`), assertion em uma linha, e `*Verificação:*` apontando para artefato concreto. ACs nunca são renumeradas; removidas viram `AC-N — REMOVED`. Ver: `01-architecture.md` (Camada 2).

**AC pass.** Camada 2 da pipeline. Agente único que parsa o PRD/Proposal linkado ao PR, valida cada AC contra `*Verificação:*` consultando o resultado da Camada 1, e emite tabela `AC | Status | Notes`.

**ADR.** Architecture Decision Record. Documento curto (context · decision · consequences) que registra decisão arquitetural não-trivial. Mora em `docs/adr/NNNN-slug.md`. Nascem durante sessões de discovery (`/grill-me`).

**Agente.** Invocação LLM com prompt focado e tools. No template, um único agente é responsável pela Camada 2 (AC pass) e N subagents pela Camada 3.

**`.agents/`.** Diretório raiz onde mora tudo de execução de agente: prompts (`.agents/prompts/`), skills/wrappers por runner (`.agents/skills/<runner>/`), rules compartilhadas (`.agents/rules/`). Fonte única.

**Area label.** Label do formato `area:*` (e.g. `area:auth`, `area:db`). Aciona subagents específicos na Camada 3 e/ou checks scoped em `docs/labels.md`. Define o "vocabulário de atenção" do projeto.

## B

**Branch protection.** Regra do GitHub configurada em Settings → Branches que exige status checks verdes + reviews antes de merge. Mecanismo do gate da Camada 4. Não é arquivo; configurado via UI.

## C

**Camada.** Estágio da pipeline. v1 tem 4: Static (CI) · AC pass (local) · Subagents (local, paralelo) · Humano (condicional). Cada camada é um filtro que reduz custo da próxima.

**CHANGELOG.** Arquivo `CHANGELOG.md` em PT-BR no formato keep-a-changelog. Entrada **obrigatória** no PR que fecha um PRD ou Proposal — validada pelo AC pass como `AC-CHANGELOG`.

**CODEOWNERS.** Arquivo em `.github/CODEOWNERS` que mapeia paths para revisores GitHub. Junto com branch protection, força revisão humana quando um path sensível é tocado. Mecanismo do gate da Camada 4.

**Code-quality (subagent).** Subagent core da Camada 3. Sempre roda. Responsável por: ler `docs/conventions.md`, rodar `scripts/quality-scan.sh`, interpretar delta vs `docs/quality.md`, propor update gated em `.reviews/<PR>-<ts>-quality-proposal.md`. Absorve o "General pass" do modelo prévio.

**Core subagent.** Subagent que **sempre roda**, independente de labels. v1: `security`, `code-quality`.

## D

**Diff.** Saída de `gh pr diff <PR> --repo <repo>`. Input principal dos subagents da Camada 3.

## G

**`gh`.** GitHub CLI. Pré-requisito do template. Usado para obter contexto do PR (`gh pr view`), baixar artifacts (`gh run download`), e postar panorama (`gh pr comment --edit-last`).

**Gitleaks.** Ferramenta de secret scanning usada na Camada 1. Detecta secrets commitados (API keys, passwords, tokens). Rodada via `make secret-scan`.

**`/grill-me`.** Skill de interview-driven discovery. Sessão de perguntas relentless que percorre a árvore de decisão antes de escrever artefato. Origem da documentação deste pacote.

## H

**Human review (Camada 4).** Gate final, condicional. Dispara quando: label de risco no PR OU subagent emite `❌ blocker`. Mecanismo: CODEOWNERS + branch protection.

## L

**Label.** Tag aplicada ao PR/Issue. Categorias:
- `area:*` — área do código (aciona subagents específicos)
- `risk:*` — nível de risco (`risk:high` aciona Camada 4)
- `feat`, `fix`, `chore`, `docs`, `refactor`, `test` — tipo de mudança (informativo)

Vocabulário completo em `docs/labels.md`.

## M

**Makefile.** Arquivo `Makefile` na raiz. Define targets `lint`, `typecheck`, `test`, `secret-scan`, `review`, `wire-runners`, `clean`, `help`. **Placeholders** para `lint`, `typecheck`, `test` — dono preenche conforme stack. Stack-agnosticismo do template vive aqui.

**Marker HTML.** String `<!-- workflow-setup:review -->` no início do panorama. Permite que re-runs identifiquem o comment anterior e sobrescrevam (uma fonte canônica por PR).

## P

**Panorama.** Documento markdown único que consolida output das Camadas 2 e 3 + veredito global. Gerado em `.reviews/<PR>-<ts>-panorama.md` e postado no PR via `gh pr comment`. Estrutura: marker HTML · header · seções por camada/subagent · veredito + gatilho de Camada 4.

**PR (Pull Request).** Unidade de mudança. Sempre referencia um PRD ou Proposal no body (`PRD: docs/prds/...` ou `Proposal: docs/proposals/...`).

**PRD.** Product Requirements Document. Mora em `docs/prds/NNNN-slug.md`. Para features que ocupam mais de 1 PR. Contém Goal, Non-goals, User stories, Acceptance criteria, Vertical slices, Open questions. Template em `docs/prds/_template.md`.

**Prompt.** Arquivo markdown em `.agents/prompts/<name>.md` com instruções completas do agente. Fonte única — wrappers em `.agents/skills/<runner>/` apenas apontam.

**Proposal.** Documento mais enxuto que PRD. Mora em `docs/proposals/NNNN-slug.md`. Para mudança que cabe em 1 PR (fix, refactor, dep bump, doc, chore). Contém Problem, Change, Non-goals, Acceptance criteria, Open questions. Template em `docs/proposals/_template.md`.

## Q

**Quality pass.** Trabalho do subagent `code-quality`. Roda `quality-scan.sh`, calcula delta vs `docs/quality.md`, propõe update em `.reviews/<PR>-<ts>-quality-proposal.md`. Nunca modifica `docs/quality.md` — humano aplica após review.

**Quality scan.** Script `scripts/quality-scan.sh` que emite JSON estável com métricas estruturais (`totalFiles`, `filesOver1000`, `todos`, `files[]` top-N; placeholders para `godClasses`, `avgCyclomaticComplexity`, `cohesion`, `coupling`, `nPlusOne`, `securityFindings`).

## R

**Reduced mode.** Comportamento do AC pass quando o PR body não cita PRD nem Proposal. Pula tabela de ACs; emite warning. Camada 3 continua normalmente.

**`.reviews/`.** Diretório local, **gitignored**, onde scripts gravam outputs efêmeros: `<PR>-<ts>-{ac-pass,security,code-quality,auth,db,architecture,panorama,quality-proposal}.md`.

**Risk label.** Label `risk:*` (e.g. `risk:high`). Aciona gate da Camada 4 (human review) independentemente de área. Aplicado pelo autor quando ele sabe que a mudança merece atenção extra.

**Runner.** Implementação LLM que executa um prompt. v1 suporta Claude, Cursor, Codex. Selecionado via `scripts/review.sh --with <runner>`. Default: `claude`.

## S

**Secret scan.** Check de Camada 1 que procura secrets commitados (API keys, passwords). Implementado via `gitleaks`. Falha → CI quebra → pipeline para antes de gastar LLM.

**Security (subagent).** Subagent core da Camada 3. Sempre roda. Procura: secrets em log, validação ausente em boundary, raw SQL com input não-parametrizado, casts inseguros, autenticação bypassada.

**Skill.** Arquivo `SKILL.md` num diretório `.agents/skills/<runner>/<name>/`. Wrapper fino que aponta para o prompt em `.agents/prompts/<name>.md`. Permite descoberta nativa pelo runner (quando `make wire-runners` foi rodado).

**Slice.** Pedaço atômico de implementação. v1 tem 4 (S1–S4) com dependências explícitas. Cada slice é uma vertical thin — entrega valor mesmo isolada.

**Stack-agnostic.** Capacidade do template de funcionar com qualquer linguagem/framework. Implementada via Makefile com placeholders — pipeline chama `make lint`, sem saber o que tem por baixo.

**Static (Camada 1).** Camada determinística da pipeline. Roda em CI. Composta por lint + typecheck + test + secret-scan. Falha aqui não gasta LLM. Ver: `01-architecture.md` (Camada 1).

**Subagent.** Agente especializado da Camada 3. v1 tem 5: 2 core (`security`, `code-quality`) + 3 area (`auth`, `db`, `architecture`). Cada um tem prompt focado em `.agents/prompts/<name>.md`. Roda em paralelo via bash `&` + `wait`.

## T

**Template (1).** Este repositório (`workflow-setup`) como **GitHub Template Repo**. Botão "Use this template" copia para um novo repo.

**Template (2).** Arquivos `_template.md` em `docs/prds/`, `docs/proposals/` que servem de base para criar documentos novos. Por convenção começam com `_`.

## V

**`*Verificação:*`.** Sub-heading dentro de um AC que aponta para o artefato concreto que comprova o AC. Pode ser path de teste (`src/lib/foo.test.ts`), path de arquivo (`docs/runbooks/...`), ou descrição de comportamento. O AC pass usa o tipo para decidir como verificar.

**Verdict (`VERDICT:`).** Última linha do output de cada subagent. Formato canônico:
```
VERDICT: ✅ ok | ⚠ findings | ❌ blocker
```
Parseada pelo orquestrador para detectar gatilho da Camada 4. Definição completa em `.agents/rules/reporting.md`.

**Vertical slice.** Pedaço de trabalho que **atravessa todas as camadas da aplicação** (UI → API → DB) e entrega valor end-to-end mesmo isolado. Antônimo: "horizontal slice" / "tracer-bullet inverted" (backend-only, UI-only).

## W

**`make wire-runners`.** Target opt-in do Makefile. Cria symlinks `.claude/skills`, `.cursor/skills`, `.codex/skills` apontando para `.agents/skills/<runner>/`. Permite descoberta nativa de slash-commands nos IDEs. Sem rodá-lo, invocação é só via `scripts/review.sh`.

**Workflow (1).** Pipeline operacional do template, descrita em `docs/workflow.md`. Cobre: quando criar PRD vs Proposal, regra de CHANGELOG, fluxo de ADR, política de labels, política de review.

**Workflow (2).** Arquivo `.github/workflows/ci.yml`. Implementação concreta da Camada 1.
