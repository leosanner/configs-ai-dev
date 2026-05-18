# 07 — Execução paralela das slices

> Status: **active**. Guia operacional para executar S1–S4 com agentes/sessões independentes, sem que pisem uns nos outros. Estende [`04-slices.md`](./04-slices.md) com **regras de concorrência** e **prompts de kickoff** prontos para usar.

## Modelo mental

Cada slice = uma **sessão isolada** (branch + conversa de agente + checkout local). Quem executa não precisa do histórico da sessão de design — só dos planning docs.

```
Sessão de design (já completa) ─── produziu docs/00..07
                                        │
                                        ▼
                              ┌─── Sessão S1 ───┐
                              │  branch: s1-skeleton
                              │  agente próprio
                              └─────────┬───────┘
                                        │ merge em main
                                        ▼
                              ┌─── Sessão S2 ───┐
                              │  branch: s2-static-layer
                              │  agente próprio
                              └─────────┬───────┘
                                        │ merge em main
                          ┌─────────────┴─────────────┐
                          ▼                           ▼
                ┌─── Sessão S3 ───┐         ┌─── Sessão S4 ───┐
                │  branch: s3-ac-pass       │  branch: s4-subagents
                │  agente próprio           │  agente próprio
                └────────┬────────┘         └────────┬────────┘
                         │                            │
                         └────────────┬───────────────┘
                                      ▼
                              Integração (humano)
                              merge ambos, conferir checklist
```

## Quando paralelizar de verdade

| Combinação | Paralelo? | Por quê |
|---|---|---|
| S1 + S2 | **não** | S2 depende do Makefile da S1. |
| S2 + S3 | **não** | S3 depende do contrato de output da Camada 1 (artifact `.reports/test-results.*`). |
| S2 + S4 | **não** | S4 depende do Makefile e do contrato. |
| **S3 + S4** | **sim** | Operam em arquivos majoritariamente disjuntos. Ver "Contrato de concorrência" abaixo. |

Em outras palavras: o paralelismo real do template é **uma única janela** — entre o fim da S2 e a integração final.

## Contrato de concorrência entre S3 e S4

Esta é a parte que [`04-slices.md`](./04-slices.md) intencionalmente deixou para cá: como S3 e S4 dividem os arquivos compartilhados.

### Matriz de ownership

| Arquivo | Quem cria | Quem modifica depois |
|---|---|---|
| `.agents/prompts/ac-pass.md` | S3 | — |
| `.agents/prompts/security.md` | S4 | — |
| `.agents/prompts/code-quality.md` | S4 | — |
| `.agents/prompts/{auth,db,architecture}.md` | S4 | — |
| `.agents/skills/<runner>/ac-pass/SKILL.md` (3 runners) | S3 | — |
| `.agents/skills/<runner>/{security,code-quality,auth,db,architecture}/SKILL.md` (15 arquivos) | S4 | — |
| `.agents/rules/reporting.md` | **S3 cria** (formato canônico `VERDICT:` + marker HTML) | S4 estende se necessário |
| `scripts/quality-scan.sh` | S4 | — |
| `docs/quality.md` | S4 | — |
| `scripts/review.sh` | S1 (stub) → **S3 e S4 ambos modificam** | ver regra abaixo |
| `docs/workflow.md` | S1 | S2 amplia Camada 1, S3 amplia Camada 2, S4 amplia Camadas 3 e 4 |
| `CHANGELOG.md` | S1 | cada slice adiciona sua entrada |

### Regra para `scripts/review.sh`

S3 e S4 ambos editam o orquestrador. Para evitar merge conflict, **S3 entrega um esqueleto explícito** que S4 preenche:

S3 deixa `scripts/review.sh` com a forma:

```bash
#!/usr/bin/env bash
set -euo pipefail
# ... parse args, get PR context, locate spec ...

# Camada 2 — AC pass (S3)
run_ac_pass "$PR" "$RUNNER" "$REVIEWS_DIR"

# Camada 3 — Subagents (S4 implementa)
# TODO(S4): launch core subagents + area subagents in parallel, wait, aggregate.
# Por enquanto: copy AC pass como panorama provisório.
cp "$REVIEWS_DIR/${PR}-${TS}-ac-pass.md" "$REVIEWS_DIR/${PR}-${TS}-panorama.md"

# Posting do panorama (S4 implementa)
# TODO(S4): gh pr comment --edit-last com marker HTML
echo "$REVIEWS_DIR/${PR}-${TS}-panorama.md"
```

S4 substitui as duas regiões `TODO(S4):` por código real. O bloco de S3 (`run_ac_pass`) permanece intocado.

**Resultado:** quando S3 e S4 fizerem merge, a única região tocada por ambos é o `scripts/review.sh`, e cada um tocou linhas diferentes — git resolve sem conflito.

### `CHANGELOG.md` e merge serial

Se S3 e S4 abrirem PR ao mesmo tempo, ambos vão adicionar entrada em `## [Não lançado]` no `CHANGELOG.md`. Conflito trivial: o segundo PR resolve manualmente.

Recomendação: combine de mergear o primeiro a ficar verde primeiro, e o segundo rebaseia.

## Como largar uma sessão (kickoff)

Cada sessão começa com um **prompt de kickoff** que carrega o agente com o contexto mínimo. Use o template abaixo, substituindo `<SLICE>`.

### Template do kickoff

```text
Você vai implementar a slice <SLICE> do template workflow-setup.

Leitura obrigatória, nesta ordem:
1. README.md (entry point)
2. docs/00-overview.md (princípios)
3. docs/02-decisions.md (decisões D-1 a D-24 com razão)
4. docs/03-target-structure.md (árvore alvo)
5. docs/04-slices.md#<slice-anchor> (escopo, AC, definição de pronto da sua slice)
6. docs/05-open-questions.md (pendências; resolva as marcadas como dono <SLICE>)
7. docs/06-glossary.md (lookup de termos)
8. docs/07-parallel-execution.md (regras de concorrência se aplica)

Crie a branch <branch>. Implemente todas as ACs declaradas na sua slice.
Cada AC tem critério de verificação concreto — siga literalmente.
Não toque em arquivos fora do "Escopo" da slice. Em caso de dúvida sobre
ownership, consulte docs/07-parallel-execution.md#matriz-de-ownership.

Quando terminar:
- Cada AC tem que estar marcada [x] no PR body.
- Adicione entrada em CHANGELOG.md sob `## [Não lançado]`.
- Abra PR com body referenciando docs/04-slices.md#<slice-anchor>.

Não revise/auto-aprove sua própria slice — a pipeline ainda não existe.
A revisão é manual pelo dono nesta fase.
```

### Tabela de kickoff por slice

| Slice | Branch | Anchor em 04-slices.md | Reads obrigatórios (linha 4) |
|---|---|---|---|
| S1 | `s1-skeleton` | `#s1--esqueleto--docs-do-template--makefile-vazio` | + nenhum extra |
| S2 | `s2-static-layer` | `#s2--camada-1--ci` | + S1 mergeado |
| S3 | `s3-ac-pass` | `#s3--camada-2--ac-pass` | + S2 mergeado |
| S4 | `s4-subagents` | `#s4--camada-3--subagents--wiring-de-runners--panorama` | + S2 mergeado, + ler `docs/07-parallel-execution.md#contrato-de-concorrência-entre-s3-e-s4` |

## Sincronização entre paralelismo S3 e S4

S3 e S4 rodam ao mesmo tempo mas precisam **se ver no fim** para integrar. Dois pontos:

1. **Ambos commitam para branches distintas** (`s3-ac-pass`, `s4-subagents`). Nenhum dá push para a branch do outro.
2. **Antes do merge final**, o dono (humano) faz:
   ```bash
   git checkout main
   git merge --no-ff s3-ac-pass    # ou via "Squash and merge" no PR
   git merge --no-ff s4-subagents  # idem
   # rodar checklist de integração em docs/04-slices.md#integração-final
   ```
3. Se houver conflict em `scripts/review.sh` apesar do esqueleto da regra de ownership, resolver **mantendo a estrutura do template**: a chamada de `run_ac_pass` da S3 permanece; os blocos da S4 substituem os TODO de S3.

## Comunicação entre sessões durante execução

Sessões diferentes **não compartilham contexto**. Toda comunicação acontece via:

- **Artefatos no repositório** (docs, código). Mudanças são vistas via `git pull --rebase` antes de continuar.
- **PR comments do GitHub** quando uma slice precisa avisar a outra sobre um ajuste.
- **`docs/05-open-questions.md`** se uma decisão precisa ser tomada que afeta as duas — atualizar lá vira fonte canônica.

**Anti-pattern:** uma sessão "lembrar" do que aconteceu em outra. Se vai impactar a outra, escreva no repo.

## Falhas que esta arquitetura tolera

| Falha | Como sobrevive |
|---|---|
| Sessão de S3 trava no meio | Outra sessão pode pegar a S3 lendo `04-slices.md` + a branch parcial. Nenhum contexto perdido fora do repo. |
| S3 e S4 divergem em interpretação de uma decisão | Conflito resolvido lendo `02-decisions.md`. Se a decisão não cobre, abrir entrada em `05-open-questions.md`, fechar com o dono. |
| Conflito de merge em `scripts/review.sh` | Documentado acima — esqueleto da S3 + blocos da S4 ocupam regiões disjuntas. |
| Conflito de merge no `CHANGELOG.md` | Trivial; o segundo PR resolve. |
| `gh` ou runner CLI mudou comportamento entre S3 e S4 | OQ-1/OQ-2 deixadas para resolução durante a slice; cada uma decide independentemente. |

## Quando NÃO paralelizar S3 e S4

Mesmo com o contrato acima, há cenários onde executar em série compensa:

- **Primeira execução do template** — você está aprendendo a forma do orquestrador. Faça S3 primeiro, releia, faça S4. O custo de paralelizar (overhead de integração) supera o benefício.
- **Você é a única pessoa** — paralelizar entre você e você mesmo é apenas troca de contexto. Mais cedo entrega quem fizer uma de cada vez bem feito.
- **Sessões de agente caras** — se cada sessão consome tokens significativos, série permite reusar contexto.

Use paralelismo quando: várias pessoas envolvidas, ou quando você quer evitar bloqueio (e.g. ficou claro durante S3 que falta info; deixa S4 progredir enquanto investiga).

## Checklist antes de declarar v1

Em ordem, após todas as 4 slices terem PRs mergeados:

- [ ] `make help` lista todos os targets (S1 AC-1).
- [ ] CI verde em `main` (S2).
- [ ] `scripts/review.sh` rodado contra um PR real do `workflow-setup` posta panorama válido (S4).
- [ ] Panorama do PR de integração mostra: AC pass + 2 subagents core + (se label `area:auth`) auth subagent.
- [ ] `make wire-runners` é idempotente em ambiente fresh-clone.
- [ ] `CHANGELOG.md` tem 4 entradas (uma por slice).
- [ ] Tag `v1.0.0` aplicada em `main`.
- [ ] Em GitHub Settings → General → "Template repository" → marcada como ✅.

Pronto: "Use this template" passa a funcionar em projetos novos.
