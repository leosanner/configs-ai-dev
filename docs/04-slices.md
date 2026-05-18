# 04 — Slices

> Status: **active**. Quatro slices independentes (S1–S4) com Acceptance Criteria, dependências entre slices e definição de pronto. Cada slice é uma vertical thin — entrega valor verificável mesmo isolada.

## Dependências entre slices

```
S1 (esqueleto + docs + Makefile vazio)
  │
  ▼
S2 (Camada 1 + CI)
  │
  ├──────────────┐
  ▼              ▼
S3 (AC pass)   S4 (Camada 3 — subagents + wiring)
   ────────┬──────────
           ▼
   Integração final
```

- **S1** não tem dependências. Pode começar imediatamente.
- **S2** depende de **S1** (precisa do Makefile com slots para preencher `lint`/`typecheck`/`test`/`secret-scan`).
- **S3** depende de **S2** (precisa do Makefile e do contrato de output da Camada 1, e.g. JUnit em `.reports/`).
- **S4** depende de **S2** (precisa do Makefile, do `quality-scan.sh` consumido pelo `code-quality`, e do `scripts/review.sh` esqueleto que S1 deixou; S3 e S4 mexem em arquivos disjuntos e podem rodar em paralelo).

**Integração final** roda depois de S3 e S4: confere que `scripts/review.sh` une as duas camadas (AC pass + Camada 3), agrega panorama, posta no PR.

## Convenções comuns

- Toda slice nasce em **branch própria** (`s1-skeleton`, `s2-static-layer`, etc.).
- Cada slice abre **um PR** com body referenciando `docs/04-slices.md#s<n>`.
- AC IDs seguem `AC-S<n>-K` (e.g. `AC-S1-3`). Estáveis após criação.
- PR de slice merge **squash** em `main`.
- Esta meta-pipeline **não se auto-revisa** durante implementação (não existem subagents ainda). Auto-revisão começa quando o template estiver completo, em projetos novos que clonarem.

---

## S1 — Esqueleto + docs do template + Makefile vazio

**Goal:** entregar a fundação tocável do template — diretórios criados, README utilizável pós-`Use this template`, Makefile com placeholders nomeados, scripts stub que ecoam "not implemented yet", PR template, e todos os docs do template (não os planning docs) que **não** dependem das camadas LLM.

### Escopo

**Criar:**
- `AGENTS.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md` (vazio em PT-BR, formato keep-a-changelog)
- `Makefile` com targets:
  - `lint` (placeholder: `@echo "preencha: comando de lint"; exit 1`)
  - `typecheck` (idem)
  - `test` (idem; documenta que deve emitir `.reports/test-results.{xml,json}`)
  - `secret-scan` (concreto: chama `gitleaks detect --report-path=.reports/gitleaks.json`)
  - `review` (proxy para `scripts/review.sh`)
  - `wire-runners` (cria symlinks `.claude/skills` → `.agents/skills/claude/`, idem cursor/codex; comentar etapa por etapa)
  - `clean` (apaga `.reports/`, `.reviews/`)
  - `help` (lista targets)
- `.gitignore` (inclui `.reviews/`, `.reports/`, `.claude/`, `.cursor/`, `.codex/` se forem symlinked)
- `scripts/review.sh` stub: imprime "not yet implemented; see docs/04-slices.md#s3" e sai com `exit 1`.
- `scripts/quality-scan.sh` stub: idem.
- `.github/PULL_REQUEST_TEMPLATE.md` com slots `PRD:` e `Proposal:` no body.
- `.agents/prompts/.gitkeep`, `.agents/skills/{claude,cursor,codex}/.gitkeep`, `.agents/rules/.gitkeep` (manter dirs vazios).
- `docs/workflow.md` — descreve a pipeline operacional do template em PT-BR para o dono operar.
- `docs/conventions.md` — esqueleto com section headers vazios.
- `docs/labels.md` — lista de labels com sintaxe completa para os 3 ativos (`area:auth`, `area:db`, `area:architecture`) e exemplos comentados para os outros.
- `docs/architecture.md` — placeholder para o dono.
- `docs/prds/_template.md`
- `docs/proposals/_template.md`
- `docs/adr/README.md` e `docs/adr/0000-record-architecture-decisions.md`.

**Não fazer:**
- Implementar lógica da Camada 1 no CI (S2).
- Implementar AC pass (S3).
- Implementar subagents (S4).
- Implementar `quality-scan.sh` (S4).
- Implementar comando real de `gitleaks` no Makefile além de chamada literal (concretização do binário fica em S2 quando o CI for testado).

### Acceptance criteria

- [ ] **AC-S1-1** — `make help` lista todos os targets esperados (`lint`, `typecheck`, `test`, `secret-scan`, `review`, `wire-runners`, `clean`, `help`) com uma linha de descrição cada.
  *Verificação:* execução manual de `make help`.
- [ ] **AC-S1-2** — `make lint`, `make typecheck`, `make test` falham com mensagem clara "preencha em <arquivo>:linha" e exit code != 0.
  *Verificação:* execução manual; mensagem cita o Makefile.
- [ ] **AC-S1-3** — `make wire-runners` cria symlinks `.claude/skills`, `.cursor/skills`, `.codex/skills` apontando para os diretórios em `.agents/skills/<runner>/`. Idempotente (rodar duas vezes não quebra).
  *Verificação:* `ls -la .claude/skills` mostra symlink após `make wire-runners`; segunda execução não quebra.
- [ ] **AC-S1-4** — `scripts/review.sh` e `scripts/quality-scan.sh` existem, são executáveis (`chmod +x`), e ao serem invocados imprimem "not yet implemented" + referência à slice que vai implementar, com exit code != 0.
  *Verificação:* execução manual.
- [ ] **AC-S1-5** — `.github/PULL_REQUEST_TEMPLATE.md` contém duas linhas reconhecíveis pelo AC pass (`PRD: docs/prds/...` e `Proposal: docs/proposals/...`), com comentário explicando qual deletar.
  *Verificação:* leitura do arquivo.
- [ ] **AC-S1-6** — `docs/workflow.md`, `docs/conventions.md`, `docs/labels.md`, `docs/architecture.md`, `docs/prds/_template.md`, `docs/proposals/_template.md`, `docs/adr/README.md` e `docs/adr/0000-record-architecture-decisions.md` existem com conteúdo coerente (não-stub, mesmo que com section headers vazios em `conventions.md`).
  *Verificação:* leitura individual.
- [ ] **AC-S1-7** — `CHANGELOG.md` existe em PT-BR com cabeçalho keep-a-changelog (`## [Não lançado]`, categorias Adicionado/Corrigido/Alterado/Removido).
  *Verificação:* leitura.
- [ ] **AC-S1-8** — `.gitignore` inclui `.reviews/`, `.reports/` e os 3 dirs de symlinks de runner.
  *Verificação:* `cat .gitignore`.

### Definição de pronto

- Todos AC marcados como `pass`.
- `make wire-runners && make help` roda limpo num clone fresco.
- README do planning não cita slice incompleta.
- PR de S1 inclui entrada no CHANGELOG.

---

## S2 — Camada 1 + CI

**Goal:** ligar a Camada 1 da pipeline. Workflow do GitHub Actions roda `lint`/`typecheck`/`test`/`secret-scan` em todo PR, falha = bloqueia. Sobe artifact com test results para Camada 2 consumir.

### Escopo

**Criar/atualizar:**
- `.github/workflows/ci.yml`:
  - Triggers: `pull_request`, `push` em `main`.
  - Concurrency group por branch.
  - Steps: checkout, `make lint`, `make typecheck`, `make test`, `make secret-scan`.
  - Upload de `.reports/test-results.*` como artifact (named `test-results-<sha>`).
  - Upload de `.reports/gitleaks.json` como artifact (named `gitleaks-<sha>`).
- `Makefile`: implementar `secret-scan` de verdade chamando `gitleaks` (assumir binário instalado em CI via setup step). Adicionar setup steps no workflow se gitleaks precisar de install (`zricethezav/gitleaks-action` ou install manual).
- `.github/CODEOWNERS`: exemplo comentado mapeando paths sensíveis para `@owner`.
- `.github/README.md`: explica passo-a-passo como configurar branch protection no GitHub UI (require pull request reviews, require status checks: CI, restrict pushes to main).
- `docs/workflow.md`: atualizar seção "Camada 1" com referência ao workflow.

**Não fazer:**
- Configurar branch protection automaticamente (não dá via arquivo).
- Tocar em `.agents/` ou em scripts de review.
- Adicionar SAST, coverage, license check ou dependency review.

### Acceptance criteria

- [ ] **AC-S2-1** — Push de branch com `make lint` falhando dispara CI e o workflow falha com a mesma mensagem.
  *Verificação:* execução manual num PR de teste; check status `lint · typecheck · test · secret-scan` aparece como vermelho.
- [ ] **AC-S2-2** — `make secret-scan` no Makefile chama `gitleaks` de verdade. Em CI, gitleaks é instalado/usado como action ou install step.
  *Verificação:* leitura do Makefile e do `ci.yml`; execução do workflow contra branch que **inclui** um secret de teste falha por essa razão.
- [ ] **AC-S2-3** — Após CI passar verde, o artifact `test-results-<sha>` contém arquivo consumível pela Camada 2 (JUnit XML ou JSON estável).
  *Verificação:* baixar artifact e abrir; deve ser parseável.
- [ ] **AC-S2-4** — `.github/CODEOWNERS` existe com exemplos comentados (e.g. `# /migrations/ @owner`, `# /.github/ @owner`, `# /security/ @owner`).
  *Verificação:* leitura.
- [ ] **AC-S2-5** — `.github/README.md` documenta o passo-a-passo de branch protection: settings → branches → main → protect, require PR, require status checks "ci", require review from Code Owners.
  *Verificação:* leitura.
- [ ] **AC-S2-6** — Workflow tem concurrency group e cancela runs anteriores no mesmo branch.
  *Verificação:* leitura do `ci.yml`; segundo push em PR cancela run anterior.

### Definição de pronto

- Todos AC marcados como `pass`.
- PR de S2 inclui execução verde do próprio CI dele.
- Entrada no CHANGELOG.

---

## S3 — Camada 2 — AC pass

**Goal:** implementar o agente da Camada 2. Lê PR body, localiza PRD/Proposal, parsa ACs, consulta resultado da Camada 1, emite seção `## AC pass` do panorama.

### Escopo

**Criar/atualizar:**
- `.agents/prompts/ac-pass.md`: prompt completo do agente. EN. Define:
  - Como obter contexto do PR via `gh pr view`.
  - Como baixar artifact da Camada 1 via `gh run download` (ou ler `.reports/` se rodando local).
  - Como parsar `## Acceptance criteria` do PRD/Proposal.
  - Lógica de classificação por tipo de `*Verificação:*` (path de teste / arquivo / descrição).
  - Formato de output (seção `## AC pass` com tabela; última linha `VERDICT: ✅ ok | ⚠ findings | ❌ blocker`).
  - Reduced mode quando não há PRD/Proposal linkado.
- `.agents/skills/claude/ac-pass/SKILL.md`: wrapper fino que aponta para `.agents/prompts/ac-pass.md`.
- `.agents/skills/cursor/ac-pass/SKILL.md`: idem para Cursor.
- `.agents/skills/codex/ac-pass/SKILL.md`: idem para Codex.
- `.agents/rules/reporting.md`: define formato canônico do `VERDICT:` e do marker HTML do panorama.
- `scripts/review.sh`: implementa Camada 2. Aceita `<PR>` posicional ou pega do branch atual via `gh pr view`. Aceita `--with claude|cursor|codex` (default `claude`). Executa o runner com o prompt do `ac-pass`. Grava saída em `.reviews/<PR>-<ts>-ac-pass.md`. **Ainda não** orquestra Camada 3 nem posta panorama — S4 completa isso.
- `docs/workflow.md`: atualizar seção "Camada 2".

**Não fazer:**
- Subagents da Camada 3 (S4).
- Posting do panorama no PR (S4).
- Agregação de outputs (S4).
- Implementar `quality-scan.sh` real (S4).

### Acceptance criteria

- [ ] **AC-S3-1** — `.agents/prompts/ac-pass.md` está completo: cobre obtenção de contexto, parsing de ACs, classificação de `*Verificação:*`, output format, reduced mode.
  *Verificação:* leitura; conteúdo cobre todas as seções listadas.
- [ ] **AC-S3-2** — `scripts/review.sh <PR>` invoca o runner Claude (default), passa o prompt do `ac-pass`, e grava `.reviews/<PR>-<ts>-ac-pass.md` com conteúdo Markdown contendo seção `## AC pass` e linha `VERDICT:`.
  *Verificação:* execução manual contra um PR de teste que tem PRD linkado.
- [ ] **AC-S3-3** — `scripts/review.sh <PR> --with cursor` e `--with codex` funcionam equivalentemente (binário do runner em PATH é pré-requisito; falha clara se ausente).
  *Verificação:* execução manual com cada runner; ausência do binário produz erro descritivo.
- [ ] **AC-S3-4** — PR sem PRD/Proposal linkado entra em reduced mode: arquivo gerado contém warning explícito e nenhuma tabela de AC.
  *Verificação:* execução manual contra PR sem link de spec.
- [ ] **AC-S3-5** — AC com `*Verificação:*` apontando para arquivo de teste presente no JUnit (passed) é marcado `pass`. AC apontando para teste failed é `fail`. AC apontando para teste ausente é `fail` com motivo `not in test report`.
  *Verificação:* PR de teste manual com 3 ACs em condições diferentes; output reflete os 3 estados corretamente.
- [ ] **AC-S3-6** — Wrappers em `.agents/skills/{claude,cursor,codex}/ac-pass/SKILL.md` existem, são finos (apontam para `.agents/prompts/ac-pass.md`), e respeitam o frontmatter esperado pelo runner.
  *Verificação:* leitura.
- [ ] **AC-S3-7** — `make review PR=<n>` é equivalente a `scripts/review.sh <n>`.
  *Verificação:* execução manual.

### Definição de pronto

- Todos AC marcados como `pass`.
- Execução end-to-end contra um PR real do próprio `workflow-setup` confirma fluxo.
- Entrada no CHANGELOG.

---

## S4 — Camada 3 — Subagents + wiring de runners + panorama

**Goal:** implementar os 5 subagents (2 core + 3 area), `quality-scan.sh`, orquestração paralela na `review.sh`, agregação do panorama e posting no PR via `gh pr comment`.

### Escopo

**Criar/atualizar:**
- `scripts/quality-scan.sh`: emite JSON estável em stdout com schema documentado em `docs/quality.md`. v0 implementa apenas:
  - `summary.totalFiles`
  - `summary.filesOver1000`
  - `summary.todos`
  - `files[]` com top 20 paths por linhas
  - placeholders zerados para métricas futuras (`godClasses`, `avgCyclomaticComplexity`, etc.)
- `docs/quality.md`: cria com tabela vazia + glossário + schema JSON.
- `.agents/prompts/security.md`
- `.agents/prompts/code-quality.md` (lê `docs/conventions.md` e `docs/quality.md`, roda `scripts/quality-scan.sh`)
- `.agents/prompts/auth.md`
- `.agents/prompts/db.md`
- `.agents/prompts/architecture.md` (lê `docs/architecture.md`)
- `.agents/skills/{claude,cursor,codex}/<name>/SKILL.md` para cada um dos 5 subagents (15 arquivos no total).
- `scripts/review.sh`: completa orquestração:
  - Após Camada 2, lê labels do PR.
  - Lança subagents core (`security`, `code-quality`) em paralelo (bash `&`). Lança area subagents se label correspondente presente.
  - `wait` por todos.
  - Agrega outputs em `.reviews/<PR>-<ts>-panorama.md`.
  - Detecta gatilho de Camada 4: label de risco ou `VERDICT: ❌ blocker` em qualquer subagent.
  - Posta panorama via `gh pr comment <PR> --edit-last --body-file <panorama>` (ou via marker HTML quando `--edit-last` não estiver disponível).
- `docs/workflow.md`: atualizar seções Camada 3 e Camada 4.

**Não fazer:**
- Implementar as 6 métricas estruturais "futuras" no `quality-scan.sh`. Schema permite, mas a implementação fica para slices subsequentes (fora do v1).
- Modificar `docs/quality.md` em execução do agente — proposta de update fica em `.reviews/<PR>-<ts>-quality-proposal.md` para humano aprovar.

### Acceptance criteria

- [ ] **AC-S4-1** — `scripts/quality-scan.sh HEAD` emite JSON válido com pelo menos `summary.totalFiles`, `summary.filesOver1000`, `summary.todos`, `files[]`.
  *Verificação:* `scripts/quality-scan.sh HEAD | jq .` retorna sem erro.
- [ ] **AC-S4-2** — Os 5 prompts em `.agents/prompts/` estão completos e cobrem inputs/outputs específicos de cada subagent. Cada prompt define `VERDICT:` na última linha.
  *Verificação:* leitura individual.
- [ ] **AC-S4-3** — 15 wrappers em `.agents/skills/<runner>/<name>/SKILL.md` existem e apontam para os prompts.
  *Verificação:* `find .agents/skills -name SKILL.md | wc -l` retorna 18 (3 runners × 6 subagents = inclui o `ac-pass` da S3).
- [ ] **AC-S4-4** — `scripts/review.sh <PR>` executa Camada 2 + Camada 3 em sequência. Camada 3 lança subagents core em paralelo via bash `&` + `wait`.
  *Verificação:* execução manual; observar PIDs paralelos (e.g. via `ps` durante execução) ou medir tempo (paralelo < soma sequencial).
- [ ] **AC-S4-5** — PR com label `area:auth` aciona subagent `auth`. PR sem labels area roda apenas core.
  *Verificação:* execução manual em ambos os casos; panorama mostra seções diferentes.
- [ ] **AC-S4-6** — Panorama final em `.reviews/<PR>-<ts>-panorama.md` agrega AC pass + N subagents em seções ordenadas, com veredito global no topo. Começa com marker HTML `<!-- workflow-setup:review -->`.
  *Verificação:* leitura do arquivo.
- [ ] **AC-S4-7** — `scripts/review.sh` posta o panorama via `gh pr comment <PR> --edit-last --body-file <panorama>`. Segunda execução no mesmo PR sobrescreve o comment anterior, não cria novo.
  *Verificação:* execução dupla manual; PR mostra um único comment, atualizado.
- [ ] **AC-S4-8** — Gatilho de Camada 4 dispara quando PR tem `area:auth`, `area:secrets`, `area:migrations`, `area:public-read` ou `risk:high`, OU quando qualquer subagent emite `VERDICT: ❌ blocker`. Quando dispara, panorama mostra linha `Human review required: yes (gatilho: <razão>)` no topo.
  *Verificação:* execução manual em PRs com cada condição.
- [ ] **AC-S4-9** — Subagent `code-quality` gera proposta de update em `.reviews/<PR>-<ts>-quality-proposal.md` mas **não** modifica `docs/quality.md`. `git status` após execução não mostra `docs/quality.md` como modificado.
  *Verificação:* execução manual; inspeção de `git status` e existência da proposta.
- [ ] **AC-S4-10** — Subagent que falha (timeout, crash) marca sua seção do panorama como `manual-review-required` e o orquestrador segue sem abortar.
  *Verificação:* simular falha (e.g. prompt inválido) num subagent; panorama final ainda é gerado com a seção marcada.

### Definição de pronto

- Todos AC marcados como `pass`.
- Execução end-to-end contra um PR real do `workflow-setup` posta um panorama útil.
- Entrada no CHANGELOG.

---

## Integração final (pós-S3 e S4)

Não é uma slice formal — é a conferência de que S3 e S4 (que mexem em arquivos disjuntos) integram corretamente.

**Checklist:**

- [ ] `scripts/review.sh <PR>` roda Camada 2 e Camada 3 sem conflito.
- [ ] AC pass aparece como **primeira** seção do panorama; subagents da Camada 3 seguem.
- [ ] Veredito global considera AC pass + todos os subagents.
- [ ] `make review PR=<n>` é o caminho-feliz documentado em `docs/workflow.md`.
- [ ] CHANGELOG tem entradas para S1, S2, S3, S4.
- [ ] Cada PR de slice referencia a próxima.

Quando todos os bullets acima estiverem ✅, o template está em **v1**. Versão é tagada (`v1.0.0`), botão "Use this template" passa a ser usável em outros projetos.
