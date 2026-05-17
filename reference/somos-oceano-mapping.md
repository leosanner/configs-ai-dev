# Referência — Mapeamento do `somos-oceano` para o template

Este documento captura o que foi extraído do projeto `somos-oceano` (em `~/projetos/clientes/somos-oceano`) durante a sessão de design do template. Serve como referência objetiva: "este princípio veio daqui", "este arquivo tem origem ali".

## Estado do `somos-oceano` na captura

Snapshot em **17 de maio de 2026**:

```text
somos-oceano/
├── CLAUDE.md                    # contexto para agentes (apontador thin)
├── CONTRIBUTING.md              # padrão de contribuição
├── CHANGELOG.md                 # PT-BR
├── README.md                    # PT-BR
├── start.md                     # sumário simples (PT-BR)
├── .claude/
│   ├── reviews/                 # outputs do /pr-review
│   ├── settings.local.json
│   ├── skills/
│   │   └── pr-review/
│   │       └── SKILL.md         # carrega docs/review-agent.md
│   └── worktrees/
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/ci.yml
├── docs/
│   ├── workflow.md
│   ├── dev-guide.md
│   ├── conventions.md
│   ├── architecture.md
│   ├── domain.md
│   ├── scope.md
│   ├── roadmap.md
│   ├── labels.md
│   ├── quality.md
│   ├── review-agent.md          # ← prompt do /pr-review
│   ├── user-help.md
│   ├── adr/
│   │   ├── README.md
│   │   ├── 0001-stack.md
│   │   └── 0002-bootstrap-choices.md
│   ├── prds/
│   │   ├── _template.md
│   │   ├── 0001-foundation.md
│   │   └── 0002-rbac.md
│   └── proposals/
│       ├── _template.md
│       └── 0001-review-tool-redesign.md
└── scripts/
    ├── review.sh                # invoca /pr-review (Claude OU Codex)
    ├── quality-scan.sh          # JSON com métricas estruturais
    └── next-steps.sh            # navega roadmap.md
```

## Os 12 princípios e sua origem

| # | Princípio | Origem no `somos-oceano` |
|---|---|---|
| 1 | Artefato escrito é contrato | `docs/workflow.md:43-51` (When to write what) |
| 2 | ACs são machine-checkable | `docs/workflow.md:60-75` (Acceptance criteria — the contract); `docs/review-agent.md:42-62` (AC pass) |
| 3 | AC IDs são estáveis | `docs/workflow.md:65-66` ("Stable IDs — `AC-N` is permanent") |
| 4 | Vertical slice = tracer-bullet | `docs/workflow.md:77-79`; `docs/dev-guide.md:30` |
| 5 | `/pr-review` é o único merge gate | `docs/workflow.md:82-93`; `docs/dev-guide.md:80-98` |
| 6 | Labels carregam contrato de review | `docs/labels.md` inteiro; `docs/review-agent.md:64-72` |
| 7 | CHANGELOG entry é AC obrigatória | `docs/workflow.md:95-113`; `docs/prds/_template.md:39-40` (AC-CHANGELOG); `docs/proposals/_template.md:31-32` |
| 8 | ADR nasce no `/grill-me` | `docs/workflow.md:123-127`; `CONTRIBUTING.md:66-68` |
| 9 | Quality é informativo antes de virar gate | `docs/quality.md:5-8` |
| 10 | Write em quality.md gated por humano | `docs/quality.md:7-8`; `docs/review-agent.md:113-125` |
| 11 | Skills são agnósticas de runner | `scripts/review.sh:91-115` (`--with claude\|codex`) |
| 12 | Idiomas | `CLAUDE.md:42-45` |

## Pipeline de 8 etapas — origem

A sequência canônica saiu de `somos-oceano/docs/workflow.md:7-40`:

```text
1. Discovery conversation       (/grill-me)
2. Written artifact             (PRD or Proposal)
3. N GitHub Issues              (/to-issues, PRD only)
4. Implementation               (/tdd + /frontend-design)
5. PR opened                    (body links PRD/Proposal)
6. Single review pass           (scripts/review.sh)
7. Squash merge to main
8. PRD/Proposal status → shipped
```

Foi adotada **integralmente** pelo template, com a única generalização sendo o `--with cursor` em `scripts/review.sh`.

## Os 4 passes do `/pr-review` — origem

`somos-oceano/docs/review-agent.md:18-126` define:

1. **Fetch PR context** (linhas 18-28).
2. **Locate driving artifact** (linhas 30-40).
3. **AC pass** (linhas 42-62).
4. **Label pass** (linhas 64-72).
5. **General code-quality pass** (linhas 74-86).
6. **Quality pass** (linhas 88-126).
7. **Emit report** (linhas 128-185).

Os passes 3-6 são **os 4 passes** do template (`AC | Label | General | Quality`).

## Templates de spec — origem

### PRD

`somos-oceano/docs/prds/_template.md` — 66 linhas. Frontmatter com status, owner, created, labels. Seções:
- `## Problem`
- `## Goal`
- `## Non-goals`
- `## User stories`
- `## Acceptance criteria` (AC-N + *Verificação:* + AC-CHANGELOG)
- `## Vertical slices`
- `## Open questions`
- `## Out of scope (future)`
- `## Related`

Adoção integral, com placeholders renomeados para agnóstico.

### Proposal

`somos-oceano/docs/proposals/_template.md` — 39 linhas. Frontmatter idêntico. Seções:
- `## Problem`
- `## Change`
- `## Non-goals`
- `## Acceptance criteria` (com AC-CHANGELOG)
- `## Open questions`

Adoção integral.

### ADR

`somos-oceano/docs/adr/README.md:9-23` define o formato:
```text
# NNNN. <Title>

- Status: Accepted | Superseded by NNNN | Deprecated
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```

Adoção integral.

## Scripts — origem

### `scripts/review.sh`

`somos-oceano/scripts/review.sh` — 124 linhas. Componentes-chave:
- Aceita `<PR>` posicional ou pega do branch atual via `gh pr view`.
- Aceita `--with claude|codex`.
- Constrói prompt fixo: "Run the /pr-review skill against PR #N. Read docs/review-agent.md and follow its pipeline exactly. Write the final Markdown report to <path>. After writing, print only that path."
- Escreve em `.claude/reviews/<PR>-<ts>-<runner>.md`.
- Retorna o path em stdout.

### `scripts/quality-scan.sh`

`somos-oceano/scripts/quality-scan.sh` — 85 linhas. Componentes-chave:
- Lê arquivos via `git ls-files`.
- Exclui binários, lockfiles, fontes (regex de extensão).
- Mede: `totalFiles`, `filesOver1000`, `todos` (TODO/FIXME).
- Emite JSON com schema documentado em `docs/quality.md`.

### `scripts/next-steps.sh`

`somos-oceano/scripts/next-steps.sh` — 266 linhas. Componentes-chave:
- Parser AWK para `docs/roadmap.md` (header `## Phase:`, fields `Status:`, `GH Label:`, `Scope:`, `Specs:`).
- Lê `status:` do frontmatter de cada spec referenciado.
- Enriquece com `gh issue list --label X` quando `gh` autenticado.
- Suporta `--all` e `--phase <name>`.
- Cores ANSI quando stdout é TTY.

## Casos de uso reais observados

### `area:*` labels (catálogo do `somos-oceano`)

Em `docs/labels.md`:
- `area:auth` (linhas 30-42): Better-Auth, signup, can(), session.
- `area:db` (linhas 44-54): Prisma schema, migrations, raw SQL.
- `area:import` (linhas 56-68): XLSX upload, parsing, validation.
- `area:public-read` (linhas 70-80): public routes, GeoJSON, PII.
- `area:secrets` (linhas 82-92): env vars, credentials, process.env.

**No template:** estes serão **exemplos comentados** em `docs/process/labels.md`. Cada projeto define seus próprios `area:*` específicos.

### Phases do roadmap

Em `docs/roadmap.md:23-66`:
- `Foundation` (shipped)
- `Review Tool` (shipped)
- `RBAC` (planned)
- `Public MVP` (planned)
- `Spreadsheet Upload` (planned)
- `Dev Guidelines` (planned)

**No template:** `docs/product/roadmap.md` virá com **um exemplo de Phase** preenchido (placeholder), seguindo o formato `## Phase: <name>` que o `next-steps.sh` parseia.

### ADRs registradas

- `0001-stack.md` (decisão da stack inicial; 62 linhas).
- `0002-bootstrap-choices.md` (decisões iniciais).

**No template:** apenas `_template.md` + `0000-record-architecture-decisions.md` (meta-ADR).

## Coisas do `somos-oceano` que NÃO entram no template

| Item | Razão |
|---|---|
| `start.md` | Sumário descritivo do projeto específico; cada projeto cria o seu em `docs/product/scope.md`. |
| `prisma/`, `vitest.workspace.ts`, `playwright.config.ts`, etc. | Específicos da stack (Next.js + Prisma). |
| `docker-compose.yml` (db local + db de teste) | Específico da stack. |
| `.husky/`, `commitlint.config.mjs` | Decisão Q8 (provavelmente fica em `CONTRIBUTING.md` mas não no template). |
| `.nvmrc`, `package.json`, `tsconfig.json`, `eslint.config.mjs`, etc. | Específicos da stack. |
| Conteúdo concreto de `domain.md` | Específico do domínio do projeto. |
| `docs/samples/` | Específico (samples de spreadsheet). |

## Coisas a generalizar com cuidado

| Item | Atenção |
|---|---|
| `.claude/` | Vira `.agent/`. Mas se o template for usado primariamente com Claude Code, pode-se manter um symlink ou cópia local. |
| `docs/conventions.md` (linhas 36-91) | É 80% TypeScript/Next/React. No template, vira stub com section headers vazios. |
| `docs/dev-guide.md` (linhas 126-161) | Seções "Database" e "Integration tests against a real Postgres" são específicas — ficam fora do template. |
| `docs/review-agent.md` (linha 56) | Comando `pnpm test <path>` precisa virar placeholder de runner de testes. |
| `scripts/quality-scan.sh` linha 38-41 | Lockfiles excluídos são `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`. No template, considerar incluir lockfiles de outros ecossistemas (`Cargo.lock`, `poetry.lock`, `Gemfile.lock`, etc.) se forem comuns. |

## Por que o `somos-oceano` foi escolhido como referência

1. **Maturidade.** O workflow não é hipotético; foi construído em uso real ao longo de várias semanas.
2. **Coerência interna.** Os 12 princípios encadeiam — quebrar um quebra os outros.
3. **Multi-runner provado.** `scripts/review.sh --with claude|codex` mostra que o pipeline tolera trocar a IDE.
4. **Documentação rica.** A conversa só foi possível porque o `somos-oceano` já tinha `docs/workflow.md`, `docs/dev-guide.md`, `docs/review-agent.md` etc. como artefatos legíveis.
5. **Tamanho ainda gerenciável.** Pequeno o suficiente para ser inspecionado em uma sessão; grande o suficiente para ter aprendido coisas reais.
