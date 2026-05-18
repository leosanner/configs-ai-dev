# 02 — Decisões fechadas

> Status: **active**. 24 decisões travadas durante a sessão de design (`/grill-me`, 18/05/2026). Cada uma cita a alternativa rejeitada e o porquê.

Formato: cada decisão tem **D-N — Título**, escolha, alternativas rejeitadas, razão. Decisões aqui são **estáveis**; mudanças exigem nota explícita no `05-open-questions.md` antes de virar nova decisão.

## D-1 — Locus do trabalho

**Decisão:** template standalone neste repositório (`workflow-setup`), sem dependência narrativa de outros projetos.

**Rejeitado:** continuar evoluindo no projeto-cliente, derivar template depois.

**Razão:** o dono quer reutilizar em N projetos sem ficar referenciando um projeto específico. Template precisa ser autossuficiente.

## D-2 — Escopo de "pipeline mais robusta"

**Decisão:** combinação de quatro coisas:
- (a) CI rodando checks determinísticos.
- (b) Soma de checks determinísticos antes de LLM.
- (c) Implementação real das 6 métricas estruturais.
- (e) Posting de resultado no GitHub PR.

**Rejeitado:** multi-runner com consenso/voting (d); histórico persistente de métricas (f); Quality como blocker (g); contrato de AC expandido (h).

**Razão:** as quatro escolhidas formam o vertical mínimo de robustez. As rejeitadas são otimizações que cabem em versões futuras sem quebrar arquitetura.

## D-3 — Onde a pipeline executa

**Decisão:** **local first**. CI no GitHub Actions só para Camada 1 (determinístico, barato). Camadas 2–4 rodam local via `scripts/review.sh`.

**Rejeitado:** local-only puro; CI-only puro.

**Razão:** custo do LLM. Assinatura existente do dono (Claude/Cursor/Codex) suporta uso interativo, não consumo automático em todo PR. CI fica para o que é grátis.

## D-4 — Faseamento Local/CI

**Decisão:** Camada 1 vai pra CI **desde o dia 1** (workflow `.github/workflows/ci.yml` ativo). Camadas 2–4 ficam local indefinidamente.

**Rejeitado:** CI desligado no v1, ligado quando o dono pedir.

**Razão:** Camada 1 é grátis e rápida. Não tem motivo para diferir.

## D-5 — Forma do entregável

**Decisão:** **GitHub Template Repo**. Botão "Use this template" copia o repositório inteiro.

**Rejeitado:** copia manual via `degit`/`git clone`; scaffolder programado (`npx create-...`); submodule/dep com upstream.

**Razão:** mais simples, versionado, sem código pra manter (scaffolder), sem acoplamento futuro (submodule). Limitação aceita: updates do template não propagam automaticamente — cada projeto-cliente fica responsável por pull manual quando quiser.

## D-6 — Limpeza de referências externas

**Decisão:** **drástica**. Apagar `reference/`, reescrever `README.md` do zero. Manter padrões e ideias (4 passes, AC contract), sem nomear projetos de origem.

**Rejeitado:** manter apêndice histórico; limpar parcialmente.

**Razão:** template precisa ser autônomo. Citação a outro projeto cria dependência de contexto.

## D-7 — Arquitetura em camadas

**Decisão:** pipeline de 4 camadas em cascata.

```
1. Static (CI, determinístico)
2. AC pass (local, agente único)
3. Subagents especializados (local, paralelo)
4. Humano (condicional)
→ Panorama no PR via gh pr comment
```

**Rejeitado:** modelo de "um único agente faz tudo" (estado prévio); modelo de "tudo determinístico" (sem LLM); modelo de "tudo LLM" (sem CI).

**Razão:** filtros em cascata com custos crescentes. Determinístico → contrato → julgamento especializado → humano. Cada camada justifica o gasto da próxima.

## D-8 — Como o resultado vira "panorama" no PR

**Decisão:** **`scripts/review.sh` auto-posta** via `gh pr comment <PR> --body-file <panorama>`. Comment único por PR, sobrescrevível.

**Rejeitado:** copy/paste manual; GitHub Check (status); workflow_dispatch via artifact.

**Razão:** menor fricção. `gh` já está autenticado no dev. Comment é editável (re-runs sobrescrevem via marker HTML), permite copy-paste e melhor que status check para conteúdo longo.

## D-9 — Repartição entre Camada 2 e Camada 3

**Decisão:** **Camada 2 = só AC pass.** Tudo que é julgamento de qualidade/risco/área vira subagent na Camada 3.

**Rejeitado:** Camada 2 mantém AC + Label + General (modelo anterior); Camada 3 fica como add-on opcional.

**Razão:** subagents paralelos com prompts focados dão mais sinal que um agente único com prompt enciclopédico. Cada subagent recebe contexto mínimo necessário.

## D-10 — Trigger da Camada 4 (humano)

**Decisão:** dispara se **(a) PR tem label de risco** (`area:auth`, `area:secrets`, `area:migrations`, `area:public-read`, `risk:high`) **OU (b) qualquer subagent emite `❌ blocker`**.

**Rejeitado:** sempre dispara (humano gate único); files perigosos (allowlist de paths); delta de Quality piora; PR grande demais.

**Razão:** label captura intenção explícita do autor. Subagent blocker captura achado automatizado. Combinação OR garante que ambos disparos válidos cobrem.

## D-11 — Estratégia de stack-agnosticismo

**Decisão:** **Makefile com placeholders nomeados.** Template entrega Makefile com targets vazios; dono preenche.

**Rejeitado:** agnóstico puro (sem arquivo de config); presets multi-stack (Node/Python/Go); assume Node baseline.

**Razão:** Makefile é universal, sintaxe óbvia, não exige instalação adicional, permite hooks pré/pós sem inventar DSL.

## D-12 — Checks determinísticos da Camada 1

**Decisão:** **lint, typecheck, test, secret-scan** (gitleaks).

**Rejeitado:** SAST (semgrep); quality-scan na Camada 1; coverage threshold; dependency review/CVE; license check.

**Razão:** mínimo que paga seu custo. SAST tem alto falso-positivo e fica melhor no subagent `security`. `quality-scan` é entrada do subagent `code-quality`. Coverage/deps/license são upgrades opcionais.

## D-13 — Lista de subagents da Camada 3

**Decisão:** 
- **Core (sempre roda):** `security`, `code-quality`.
- **Area-specific (roda por label):** `auth`, `db`, `architecture`.

**Rejeitado:** `area:performance`, `area:ux`, `area:public-read`, `general-conventions`.

**Razão:** lista enxuta para v1. Os rejeitados ficam como exemplos comentados em `docs/labels.md` para o dono adaptar. `general-conventions` é absorvido pelo `code-quality` (que lê `docs/conventions.md`).

## D-14 — Como AC pass verifica testes

**Decisão:** **Camada 2 consulta o resultado da Camada 1.** Zero re-execução. Lê JUnit/JSON gerado pelo `make test` da CI.

**Rejeitado:** re-rodar apenas o teste do AC (modelo anterior); verificar só existência do arquivo; pular testes no AC pass.

**Razão:** cada teste roda uma vez por commit. Re-execução é desperdício de tempo, CI já confirmou.

## D-15 — Onde mora o Quality pass

**Decisão:** vira **trabalho do subagent core `code-quality`** na Camada 3. Lê `scripts/quality-scan.sh`, interpreta delta vs snapshot persistido, propõe update gated por humano.

**Rejeitado:** voltar à Camada 1 (deterministic + sem interpretação); subagent dedicado `metrics` separado de `code-quality`; fora do escopo do v1.

**Razão:** delta de métricas precisa de julgamento contextual (não toda regressão é problema). Subagent `code-quality` já lê `docs/conventions.md` — coerente ter as duas responsabilidades juntas.

## D-16 — Shape do orquestrador

**Decisão:** **um único `scripts/review.sh`** que orquestra as 4 camadas. Camada 3 roda em paralelo via bash `&` + `wait`.

**Rejeitado:** Camada 3 sequencial; scripts separados por camada; agente da Camada 2 orquestra Camada 3 internamente.

**Razão:** simplicidade. Bash é portátil. Paralelismo via `&` é trivial. Debug é leitura linear do script. Não inventar abstração até precisar.

## D-17 — Formato do arquivo de config de stack

**Decisão:** **Makefile.**

**Rejeitado:** Justfile (exige `just` instalado); YAML (precisa parser); package.json scripts (exclui não-Node); pipeline.env (sourced).

**Razão:** universal, instalado em todo Unix, sintaxe declarativa óbvia, suporta dependências entre targets, suporta variáveis e overrides via linha de comando.

## D-18 — Mecanismo do gate humano

**Decisão:** **CODEOWNERS + branch protection.** GitHub bloqueia merge sem aprovação do owner do path. Panorama sinaliza explicitamente que human review é necessário.

**Rejeitado:** sinalização apenas; label `needs-human-review` + workflow bloqueador; híbrido.

**Razão:** mecanismo nativo do GitHub, sem código nosso. CODEOWNERS expressa naturalmente "essa pasta exige revisão do dono".

## D-19 — Runners suportados no v1

**Decisão:** **os três** — Claude, Cursor, Codex. Selecionados via `scripts/review.sh --with <runner>` (default: claude).

**Rejeitado:** subset de dois; só Cursor; só Claude.

**Razão:** o dono usa os três pessoalmente. Pattern de wrapper fino é barato — adicionar runner é arquivo de ~10 linhas.

## D-20 — Layout de diretórios

**Decisão:** 
- `docs/` — documentação humana (PRDs, Proposals, ADRs, conventions, workflow, labels, architecture).
- `.agents/` — tudo de execução do agente (prompts, skills, rules).
- `.agents/skills/<runner>/<name>/` — wrappers finos por runner, opt-in symlinks para `.claude/`, `.cursor/`, `.codex/` via `make wire-runners`.
- `scripts/` — `review.sh` e `quality-scan.sh`.
- `Makefile` — placeholders de stack.
- `.github/` — workflows da Camada 1, CODEOWNERS, PR template.
- `.reviews/` — gitignored, outputs locais do agente.

**Rejeitado:** tradicional com `.claude/`, `.cursor/`, `.codex/` na raiz; `.tools/review/` separado.

**Razão:** separação semântica clara entre "humanos lêem" e "agentes consomem". Symlinks via `make wire-runners` resolvem descoberta nativa do IDE sem duplicar arquivos.

## D-21 — Descoberta de runners (continuação de D-20)

**Decisão:** `.agents/` é fonte única. `make wire-runners` é **opt-in** e cria symlinks `.claude/skills` → `.agents/skills/claude/` (etc.). Quem não roda `make wire-runners` invoca via `scripts/review.sh` apenas.

**Rejeitado:** `.agents/` puro sem symlinks (perde IDE discovery); arquivos duplicados commitados em `.claude/`, `.cursor/`, `.codex/`.

**Razão:** evita duplicação de fonte. Custo: usuário precisa rodar `make wire-runners` uma vez se quiser slash-command no IDE.

## D-22 — Quando fazer cleanup do repo atual

**Decisão:** **agora**, junto com a escrita do plano. README reescrito; `reference/` apagado.

**Rejeitado:** primeira tarefa da S1; postergar até fim.

**Razão:** plano e cleanup são complementares. README novo é o entry point que substitui o antigo.

## D-23 — Slicing para paralelismo

**Decisão:** **4 slices** com dependências:
- S1 (esqueleto + docs do template + Makefile vazio). Sem deps.
- S2 (Camada 1 + CI). Depende de S1.
- S3 (Camada 2 — AC pass). Depende de S2 (precisa do Makefile + JUnit output).
- S4 (Camada 3 — subagents + wiring de runners). Depende de S2.

Ordem: S1 → S2 → (S3 ∥ S4).

**Rejeitado:** vertical mínimo com 1 subagent; 2 slices grandes; 6+ slices pequenas.

**Razão:** S1 e S2 são série porque S2 depende do Makefile. S3 e S4 são paralelizáveis porque consomem o mesmo Makefile e produzem outputs independentes. 4 slices é o ponto onde paralelismo compensa overhead de integração.

## D-24 — Política de idioma

**Decisão (herdada do README original, mantida explicitamente):**
- **Planning docs** (`workflow-setup` agora): PT-BR.
- **README, CHANGELOG, user-help** do template entregue: PT-BR.
- **Workflow internals, conventions, prompts de agentes**: EN.

**Rejeitado:** tudo EN; tudo PT-BR.

**Razão:** PT-BR é onboarding do dono e leitura do cliente. EN é padrão para runners de IA e literatura de processo.

## Decisões silenciosas (aplicadas sem grilling)

Anotadas aqui para auditoria.

- **`docs/conventions.md`** continua existindo no template. Lido pelo subagent `code-quality`. Substitui o General pass do modelo anterior sem precisar de subagent dedicado.
- **Pattern de prompt SoT + wrappers finos** é mantido. Prompts em `.agents/prompts/<name>.md`; wrappers em `.agents/skills/<runner>/<name>/`.
- **Re-runs do panorama sobrescrevem** o comment anterior via marker HTML `<!-- workflow-setup:review -->`. Uma fonte canônica por PR.
- **Subagent que falha por timeout** marca a seção como `manual-review-required` e segue. Não derruba pipeline.
- **`.reviews/`** é gitignored — outputs locais não vão pro git.
