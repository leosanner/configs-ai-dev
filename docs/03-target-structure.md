# 03 — Estrutura final do template

> Status: **active**. Árvore alvo do template após as 4 slices implementadas. Cada arquivo tem dono, propósito e quando é tocado.

## Árvore alvo

```text
workflow-setup/
├── README.md                                 # entry point do template (não-planning)
├── AGENTS.md                                 # primary doc para qualquer agente que abrir o repo
├── CONTRIBUTING.md                           # padrão de contribuição + commit/CHANGELOG
├── CHANGELOG.md                              # PT-BR, keep-a-changelog
├── Makefile                                  # placeholders de stack (D-11, D-17)
├── .gitignore                                # exclui .reviews/, .reports/, etc.
│
├── .github/
│   ├── workflows/
│   │   └── ci.yml                            # Camada 1 (lint/typecheck/test/secret-scan)
│   ├── CODEOWNERS                            # exemplo, mapeia paths sensíveis
│   ├── PULL_REQUEST_TEMPLATE.md              # body com slots PRD/Proposal
│   └── README.md                             # como configurar branch protection (manual)
│
├── .agents/                                  # SoT de execução (D-20)
│   ├── prompts/                              # prompts dos subagents (EN)
│   │   ├── ac-pass.md                        # Camada 2
│   │   ├── security.md                       # Camada 3, core
│   │   ├── code-quality.md                   # Camada 3, core (lê docs/conventions.md)
│   │   ├── auth.md                           # Camada 3, area:auth
│   │   ├── db.md                             # Camada 3, area:db
│   │   └── architecture.md                   # Camada 3, area:architecture
│   ├── skills/                               # wrappers finos por runner (D-19, D-21)
│   │   ├── claude/
│   │   │   ├── ac-pass/SKILL.md
│   │   │   ├── security/SKILL.md
│   │   │   ├── code-quality/SKILL.md
│   │   │   ├── auth/SKILL.md
│   │   │   ├── db/SKILL.md
│   │   │   └── architecture/SKILL.md
│   │   ├── cursor/
│   │   │   └── (mesma estrutura)
│   │   └── codex/
│   │       └── (mesma estrutura)
│   └── rules/                                # políticas comuns referenciadas pelos prompts
│       └── reporting.md                      # formato do veredito `VERDICT: ...`, marker HTML
│
├── docs/                                     # documentação humana
│   ├── 00-overview.md                        # planning (este pacote)
│   ├── 01-architecture.md                    # planning
│   ├── 02-decisions.md                       # planning
│   ├── 03-target-structure.md                # planning (este arquivo)
│   ├── 04-slices.md                          # planning
│   ├── 05-open-questions.md                  # planning
│   ├── 06-glossary.md                        # planning
│   ├── workflow.md                           # como o pipeline opera (do template)
│   ├── conventions.md                        # convenções de código (lido pelo code-quality)
│   ├── labels.md                             # vocabulário de labels area:* e risk:*
│   ├── architecture.md                       # placeholder para o projeto-cliente
│   ├── quality.md                            # snapshot persistido de métricas estruturais
│   ├── prds/
│   │   └── _template.md                      # template de PRD
│   ├── proposals/
│   │   └── _template.md                      # template de Proposal
│   └── adr/
│       ├── README.md                         # formato e workflow de ADRs
│       └── 0000-record-architecture-decisions.md  # meta-ADR
│
├── scripts/
│   ├── review.sh                             # orquestrador das 4 camadas (D-16)
│   └── quality-scan.sh                       # JSON de métricas estruturais (D-15)
│
└── .reviews/                                 # gitignored, outputs locais do agente
    └── (criado em runtime; <PR>-<ts>-*.md)
```

## Responsabilidade por arquivo

### Raiz

| Arquivo | Dono | Toca quando |
|---|---|---|
| `README.md` | template | S1 — entry point pós-clone, explica como usar |
| `AGENTS.md` | template | S1 — orienta qualquer agente que abrir o repo (apontador para `.agents/`) |
| `CONTRIBUTING.md` | template | S1 — workflow, conventional commits, CHANGELOG entry rules |
| `CHANGELOG.md` | template | S1 — vazio inicial em PT-BR, formato keep-a-changelog |
| `Makefile` | template | S1 — define targets `lint`/`typecheck`/`test`/`secret-scan`/`wire-runners`/`review` |
| `.gitignore` | template | S1 — inclui `.reviews/`, `.reports/`, e os usuais |

### `.github/`

| Arquivo | Dono | Slice | Propósito |
|---|---|---|---|
| `workflows/ci.yml` | template | S2 | Camada 1. Roda `make lint typecheck test secret-scan` em todo PR e push. Sobe artifact com `.reports/test-results.*` para a Camada 2 consumir. |
| `CODEOWNERS` | template | S2/S3 | Exemplo comentado. Dono customiza paths. |
| `PULL_REQUEST_TEMPLATE.md` | template | S1 | Body com slots `PRD:` e `Proposal:` reconhecidos pelo AC pass. |
| `README.md` | template | S2 | Explica como configurar branch protection (não é arquivo, é settings page). |

### `.agents/`

| Arquivo/diretório | Dono | Slice | Propósito |
|---|---|---|---|
| `prompts/ac-pass.md` | template | S3 | Prompt do agente da Camada 2. EN. Define como localizar PRD/Proposal, parsear ACs, consultar resultados de teste. |
| `prompts/security.md` | template | S4 | Prompt do subagent `security`. EN. Define cobertura de checks (secrets, validação, injection, etc.). |
| `prompts/code-quality.md` | template | S4 | Prompt do subagent `code-quality`. EN. Inclui leitura de `docs/conventions.md` e interpretação de delta de `quality-scan.sh`. |
| `prompts/auth.md` | template | S4 | Prompt do subagent area:auth. |
| `prompts/db.md` | template | S4 | Prompt do subagent area:db. |
| `prompts/architecture.md` | template | S4 | Prompt do subagent area:architecture. |
| `skills/<runner>/<name>/SKILL.md` | template | S4 | Wrapper fino. Aponta para `.agents/prompts/<name>.md`. Adiciona metadata específico do runner (e.g. frontmatter do Claude Code). |
| `rules/reporting.md` | template | S3/S4 | Define formato do `VERDICT:` na última linha do output, marker HTML do panorama, e estrutura de seções. Compartilhado por todos os subagents. |

### `docs/`

| Arquivo | Dono | Slice | Propósito |
|---|---|---|---|
| `00-..06-*.md` | planning | (agora) | Este pacote de planejamento. Mantido no template como referência histórica. |
| `workflow.md` | template | S1 | Como a pipeline opera. PT-BR para o dono operar. |
| `conventions.md` | template | S1 | Convenções de código. Vem com **section headers vazios** para o dono preencher conforme stack. Lido pelo `code-quality`. |
| `labels.md` | template | S1 | Vocabulário de labels. Inclui `area:auth`, `area:db`, `area:architecture` ativos; `area:performance`, `area:ux`, `area:public-read` como exemplos comentados. |
| `architecture.md` | template | S1 | Placeholder para o dono preencher com arquitetura do projeto-cliente. Lido pelo subagent `architecture`. |
| `quality.md` | template | S4 | Snapshot persistido das métricas estruturais. Updates gated por humano. Schema do JSON do `quality-scan.sh` documentado aqui. |
| `prds/_template.md` | template | S1 | Template de PRD. Frontmatter + seções padrão. AC-N com `*Verificação:*` + AC-CHANGELOG. |
| `proposals/_template.md` | template | S1 | Template de Proposal. Mais enxuto. |
| `adr/README.md` | template | S1 | Formato e workflow de ADRs. |
| `adr/0000-record-architecture-decisions.md` | template | S1 | Meta-ADR registrando que ADRs serão usados. |

### `scripts/`

| Arquivo | Dono | Slice | Propósito |
|---|---|---|---|
| `review.sh` | template | S1 (stub) → S3 → S4 | Orquestrador. S1 entrega stub que só ecoa "not implemented". S3 implementa Camada 2. S4 implementa orquestração paralela da Camada 3 e posting do panorama. |
| `quality-scan.sh` | template | S4 | Emite JSON de métricas. v0 mínimo: `totalFiles`, `filesOver1000`, `todos`. Schema extensível. |

### `.reviews/`

Criado em runtime quando `scripts/review.sh` roda. **Gitignored**. Contém:
- `<PR>-<ts>-ac-pass.md` (Camada 2)
- `<PR>-<ts>-{security,code-quality,auth,db,architecture}.md` (Camada 3, paralelos)
- `<PR>-<ts>-panorama.md` (agregação)
- `<PR>-<ts>-quality-proposal.md` (proposta de update para `docs/quality.md`, gated por humano)

## Convenções de nomeação

- **Slices**: `S<n>-<slug>` (`S1-skeleton`, `S2-static-layer`, `S3-ac-pass`, `S4-subagents`).
- **PRDs**: `docs/prds/NNNN-slug.md` (4 dígitos, slug kebab-case).
- **Proposals**: `docs/proposals/NNNN-slug.md`.
- **ADRs**: `docs/adr/NNNN-slug.md`.
- **AC IDs**: `AC-N` (estáveis, não-renumeráveis).
- **Subagent prompts**: `.agents/prompts/<single-word>.md`.

## Encadeamento de leituras

Quando um arquivo X aponta para um arquivo Y, o link é direto e relativo. Lista das dependências de leitura cruzada:

| Origem | Lê | Quando |
|---|---|---|
| `scripts/review.sh` | `.agents/prompts/<name>.md` | runtime, ao invocar cada subagent |
| `.agents/skills/<runner>/<name>/SKILL.md` | `.agents/prompts/<name>.md` | runtime, runner discovery |
| `.agents/prompts/code-quality.md` | `docs/conventions.md`, `docs/quality.md` | runtime, contexto do subagent |
| `.agents/prompts/architecture.md` | `docs/architecture.md` | runtime, contexto do subagent |
| `.agents/prompts/ac-pass.md` | PR body, `docs/prds/*.md` ou `docs/proposals/*.md`, `.reports/test-results.*` | runtime |
| `docs/workflow.md` | `docs/labels.md`, `docs/conventions.md`, `docs/quality.md` | leitura humana |

## O que **não** mora no template

Explicitado para evitar bloat:

- Código de aplicação. O template é só pipeline.
- Configurações de lint/format específicas (eslint, prettier, ruff). Dono adiciona.
- Lockfiles, manifests de dependência. Dono adiciona.
- `node_modules/`, `target/`, `__pycache__/`, etc. Dono adiciona ao `.gitignore` quando necessário.
- Skills genéricas de IA (frontend-design, tdd, etc.). Template é focado em review.
