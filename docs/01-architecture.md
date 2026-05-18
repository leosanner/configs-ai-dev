# 01 — Arquitetura

> Status: **active**. Detalha cada uma das 4 camadas, o fluxo de dados entre elas, o orquestrador, e as garantias semânticas que o template oferece.

## Vista de cima

A pipeline é uma sequência de **filtros em cascata**, do barato para o caro, com **paralelismo dentro de uma única camada** (Camada 3). O orquestrador é um único `scripts/review.sh` rodado pelo desenvolvedor localmente. CI (`.github/workflows/`) cuida apenas da Camada 1.

```
trigger:                                            output:
  push                                                gh pr comment
   │                                                       ▲
   ▼                                                       │
[Camada 1: Static, CI]   ────── falhou ──── stop ─────────┐│
   │ ok                                                    ││
   ▼                                                       ││
[Camada 2: AC pass, local]                                 ││
   │ findings                                              ││
   ▼                                                       ││
[Camada 3: Subagents, local, paralelo] ────────────────────┤│
   │                                                        │
   ▼                                                        │
[Agregação + detecção de gatilho Camada 4]  ────────────────┘
   │
   ▼ (se gatilho disparou)
[Camada 4: Humano via CODEOWNERS + branch protection]
```

Cada camada tem **artefatos de entrada** e **artefatos de saída** bem definidos. Esses artefatos são o que cabeia uma camada na próxima.

## Camada 1 — Static (CI)

**Onde roda:** GitHub Actions.
**Quando roda:** automaticamente em todo `push` e `pull_request`.
**Custo:** zero (free tier do Actions, ferramentas estáticas).

**Checks:**

| Check | Comando | Stack-specific? |
|---|---|---|
| Lint | `make lint` | sim — placeholder no Makefile |
| Typecheck | `make typecheck` | sim — placeholder no Makefile |
| Test | `make test` | sim — placeholder no Makefile |
| Secret scan | `gitleaks detect --report-path=...` | não — ferramenta concreta |

**Contrato com a Camada 2:** o job de `test` **deve** emitir um relatório consumível pela Camada 2 (JUnit XML, ou JSON estável). O Makefile do template define o path de saída padrão: `.reports/test-results.{xml,json}`. Quem implementa `make test` é responsável por respeitar esse contrato.

**Falha aqui = pipeline para.** Não chama LLM. Não posta comment. Autor corrige e re-push.

**Não rodam aqui (intencional):**

- SAST profundo (Semgrep). Cabe ao subagent `security` da Camada 3.
- `quality-scan.sh`. Métrica é responsabilidade do subagent `code-quality`.
- Conventions / style enforcement além do lint config. Cabe ao `code-quality`.

**Razão da exclusão:** ferramentas estáticas com alto falso-positivo geram fricção. LLM tem mais contexto, decide melhor o que é sinal vs ruído. O custo é controlado porque já passamos pela porta da Camada 1.

## Camada 2 — AC pass (local, agente único)

**Onde roda:** local, invocado por `scripts/review.sh`.
**Quando roda:** quando o desenvolvedor invoca; também via `gh pr checks`-style polling em CI (futuro).
**Custo:** ~1 chamada LLM, contexto pequeno.

**Inputs:**

- Número do PR.
- Body do PR (lido via `gh pr view`) — espera linha `PRD: docs/prds/NNNN-slug.md` ou `Proposal: docs/proposals/NNNN-slug.md`.
- Resultado dos testes da Camada 1 (`.reports/test-results.{xml,json}` baixado via `gh run download` ou regenerado localmente).

**Pipeline interno:**

1. **Locate the driving artifact.** Parse do body do PR. Se não encontrar PRD nem Proposal, entra em **reduced mode** (pula AC pass, registra warning no panorama).
2. **Parse Acceptance criteria.** Ler `## Acceptance criteria` do artefato. Cada AC tem a forma:
   ```
   - [ ] **AC-N** — <assertion>. *Verificação:* <artifact reference>
   ```
3. **Para cada AC**, identificar `*Verificação:*` e classificar:
   - **Path de teste** (e.g. `src/lib/auth/can.test.ts`) → procurar esse path nos resultados de teste da Camada 1. Se passou: `pass`. Se falhou ou não foi executado: `fail`.
   - **Path de arquivo não-teste** (e.g. `docs/runbooks/deploy.md`) → verificar existência (`ls`).
   - **Descrição de comportamento** sem path → marcar como `manual-review-required`.
4. **Emitir** seção `## AC pass` do panorama com tabela `AC | Status | Notes`.

**Output:** `.reviews/<PR>-<ts>-ac-pass.md` (fragmento markdown).

**Veredito local desta camada:** `pass` (todos AC `pass` ou `manual-review-required`) ou `fail` (qualquer AC `fail`). Independente do veredito, a Camada 3 sempre executa — porque os subagents de qualidade/security/area dão sinal útil mesmo num PR com ACs falhando.

## Camada 3 — Subagents especializados (local, paralelo)

**Onde roda:** local, invocado por `scripts/review.sh` após Camada 2.
**Quando roda:** sempre. Subset depende de labels do PR.
**Custo:** N chamadas LLM em paralelo. N = 2 (core) + 0–3 (area-specific).

### Lista de subagents

| Subagent | Tipo | Dispara quando | Lê | Output |
|---|---|---|---|---|
| `security` | core | sempre | diff do PR | findings de segurança |
| `code-quality` | core | sempre | diff + `quality-scan.sh` + `docs/conventions.md` | findings de qualidade + delta de métricas |
| `auth` | area | label `area:auth` no PR | diff em fluxos de auth/sessão/RBAC | findings específicos |
| `db` | area | label `area:db` no PR | diff em migrations/queries/schema | findings de DB |
| `architecture` | area | label `area:architecture` no PR | diff + `docs/architecture.md` | findings de fronteira de módulo |

### Orquestração paralela

`scripts/review.sh` dispara cada subagent aplicável em background (bash `&`), coleta os PIDs, espera (`wait`), e agrega.

```bash
# pseudo
launch_subagent security &  PIDS+=($!)
launch_subagent code-quality &  PIDS+=($!)
[[ "$LABELS" == *"area:auth"* ]] && launch_subagent auth &  PIDS+=($!)
[[ "$LABELS" == *"area:db"* ]] && launch_subagent db &  PIDS+=($!)
[[ "$LABELS" == *"area:architecture"* ]] && launch_subagent architecture &  PIDS+=($!)
wait "${PIDS[@]}"
```

Cada `launch_subagent` invoca o runner (Claude/Cursor/Codex) com o prompt do subagent em `.agents/prompts/<name>.md` e o output redirecionado para `.reviews/<PR>-<ts>-<name>.md`.

**Timeouts e falhas:** subagent que falha (timeout ou erro do runner) **não derruba a pipeline**. O panorama marca a seção daquele subagent como `manual-review-required` e segue. Critério de timeout: TODO da slice S4 (provavelmente 5 minutos por subagent).

### Veredito por subagent

Cada subagent emite, ao fim do output, **uma linha de veredito** em formato canônico:

```
VERDICT: ✅ ok | ⚠ findings | ❌ blocker
```

`scripts/review.sh` faz `grep` dessa linha para detectar gatilho da Camada 4.

## Agregação e panorama

Depois que Camada 3 termina, `scripts/review.sh`:

1. **Concatena** os fragmentos `.reviews/<PR>-<ts>-*.md` em um único `panorama.md` com seções ordenadas.
2. **Computa veredito global:**
   - `❌ blockers` se qualquer subagent emitiu `❌` ou se algum AC é `fail`.
   - `⚠ findings to address` se há findings mas nenhum blocker.
   - `✅ ready to merge` caso contrário.
3. **Detecta gatilho de Camada 4:**
   - PR tem label em `{area:auth, area:secrets, area:migrations, area:public-read, risk:high}` (lista em `docs/labels.md`), OU
   - Qualquer subagent emitiu `❌ blocker`.
4. **Posta** o panorama via:
   ```bash
   gh pr comment <PR> --edit-last --body-file panorama.md
   # ou com marker HTML se --edit-last não estiver disponível
   ```
   O panorama começa com um marker HTML único: `<!-- workflow-setup:review -->`. Re-runs identificam o comment anterior pelo marker e sobrescrevem.

## Camada 4 — Humano

**Onde "roda":** GitHub UI. Não é código nosso; é mecanismo do GitHub.
**Quando dispara:** ver "detecção de gatilho" acima.
**Mecanismo:** `CODEOWNERS` + branch protection rule "require review".

**Como o template entrega:**

- Um `CODEOWNERS` de exemplo em `.github/CODEOWNERS` mapeando paths sensíveis (`/.github/`, `/migrations/`, `/security/`, etc.) para o owner.
- Um README em `.github/CODEOWNERS.md` explicando como configurar branch protection no GitHub UI (não dá para fazer via arquivo, precisa de API ou settings page).
- O panorama, no topo, declara explicitamente: `Human review required: yes (gatilho: <razão>)` quando aplicável.

**O template não bloqueia merge sozinho** — apenas sinaliza no panorama e confia que a branch protection do GitHub aplica a regra. Se o dono não configurou branch protection, a sinalização é só visual.

## Runners suportados

| Runner | Comando-base (a confirmar na S4) | Wrapper em |
|---|---|---|
| Claude | `claude --print --permission-mode bypassPermissions "<prompt>"` | `.agents/skills/claude/<name>/SKILL.md` |
| Cursor | `cursor-agent <prompt>` (TBC — depende da CLI atual do Cursor) | `.agents/skills/cursor/<name>/SKILL.md` |
| Codex | `codex exec --dangerously-bypass-approvals-and-sandbox "<prompt>"` | `.agents/skills/codex/<name>/SKILL.md` |

`scripts/review.sh --with <runner>` seleciona qual usar. Default: `claude`.

Os prompts dos subagents vivem em `.agents/prompts/<name>.md` (fonte única). Os wrappers em `.agents/skills/<runner>/<name>/` são finos: apontam para o prompt e ajustam metadata específico do runner.

**Descoberta nativa pelo IDE:** Claude Code procura skills em `.claude/skills/` (root do projeto). Cursor em `.cursor/`. Codex em `.codex/`. O template oferece um `make wire-runners` opcional que cria symlinks `.claude/skills` → `.agents/skills/claude/`, etc. Quem não quer slash-command no IDE não roda `make wire-runners` e invoca tudo via `scripts/review.sh`.

## Fluxo de dados (artefatos)

```
┌─ inputs ──────────────────────────────────────────────────────┐
│  Makefile                  ← stack-specific commands           │
│  docs/prds/NNNN-*.md       ← PRD com ACs                       │
│  docs/proposals/NNNN-*.md  ← Proposal com ACs                  │
│  docs/conventions.md       ← regras de qualidade               │
│  docs/labels.md            ← vocabulário de labels area:*      │
│  docs/architecture.md      ← lido pelo subagent `architecture` │
│  .agents/prompts/<name>.md ← prompts dos subagents             │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ camada 1 (CI) ──────────────────────────────────────────────┐
│  emite: .reports/test-results.{xml,json}                      │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ camada 2 (local) ───────────────────────────────────────────┐
│  consome: .reports/test-results.*, PRD/Proposal               │
│  emite:   .reviews/<PR>-<ts>-ac-pass.md                       │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ camada 3 (local, paralelo) ─────────────────────────────────┐
│  consome: diff, docs/conventions.md, quality-scan.sh output   │
│  emite:   .reviews/<PR>-<ts>-{security,code-quality,...}.md   │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ agregação ───────────────────────────────────────────────────┐
│  consome: todos os .reviews/<PR>-<ts>-*.md                    │
│  emite:   .reviews/<PR>-<ts>-panorama.md                      │
│  ação:    gh pr comment ... --edit-last                       │
└───────────────────────────────────────────────────────────────┘
```

`.reviews/` é **gitignored**. Saída é local, efêmera. O panorama no GitHub é a única superfície persistente.

## Garantias semânticas

O que o dono pode contar:

1. **Custo é predizível.** Camada 1 grátis. Camada 2 = 1 chamada LLM curta. Camada 3 = entre 2 e 5 chamadas LLM paralelas (core sempre, area opcional).
2. **Falha cedo.** Lint quebrado não vira gasto de LLM.
3. **Re-run idempotente.** Rodar `scripts/review.sh` duas vezes no mesmo PR substitui o comment, não acumula ruído.
4. **Sobreposição zero entre runners.** Mesmo prompt em `.agents/prompts/<name>.md`. Wrappers diferentes só para adaptar invocação.
5. **Stack-agnóstico no nível do template.** Trocar de Node para Python afeta o Makefile; não afeta a pipeline.

## O que sai (não-funcionalidades intencionais)

Repetido de `00-overview.md` para travar no detalhe:

- Nenhum gate automatizado bloqueia merge — sempre branch protection do GitHub.
- Sem auto-merge — humano confirma o último clique.
- Sem histórico persistente de métricas em DB.
- Sem consenso multi-modelo (subagent roda em um único runner por vez).
- Sem retry automático de subagent que falhou — humano decide.
