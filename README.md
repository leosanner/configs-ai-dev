# workflow-setup

Template **GitHub** para uma pipeline de code review em quatro camadas, agnóstica de stack e portátil entre runners de IA (Claude, Cursor, Codex).

> Status: **planejamento concluído, implementação pendente.** O conteúdo executável (Makefile, scripts, prompts, workflow de CI) ainda não foi escrito — este repositório, na captura atual, contém apenas a documentação de design que sustenta a implementação subsequente.

## Para que serve

Quando estiver pronto, este repositório será usado como **GitHub Template Repo**: o botão "Use this template" cria um novo repositório com a pipeline já cabeada. O dono do projeto-cliente preenche os placeholders da stack (comandos de `lint`, `typecheck`, `test`) e a pipeline começa a operar como gate de merge.

A pipeline em si tem **quatro camadas, executadas em ordem**:

```
1. Static  (CI, determinístico)        →  lint · typecheck · test · secret-scan
2. AC pass (agente único, local)       →  verifica cada AC do PRD/Proposal contra o resultado da Camada 1
3. Subagents (paralelos, local)        →  security · code-quality · (auth · db · architecture, por label)
4. Humano  (condicional)               →  disparado por label de risco ou subagent que emite blocker

→ Panorama consolidado postado no PR via `gh pr comment`.
```

A motivação dessa estrutura, a derivação de cada decisão, a árvore final do template e o sequenciamento de implementação estão em `docs/`.

## Como ler este repositório

| # | Arquivo | Para que serve |
|---|---|---|
| 0 | Este `README.md` | Entry point. Você está aqui. |
| 1 | [`docs/00-overview.md`](./docs/00-overview.md) | Visão geral do projeto, audiência, princípios e mapa de leitura. |
| 2 | [`docs/01-architecture.md`](./docs/01-architecture.md) | A pipeline em 4 camadas: o que cada uma faz, como conversam, onde rodam. |
| 3 | [`docs/02-decisions.md`](./docs/02-decisions.md) | 24 decisões fechadas durante a sessão de design, com justificativa. |
| 4 | [`docs/03-target-structure.md`](./docs/03-target-structure.md) | Árvore final do template e responsabilidade de cada arquivo/diretório. |
| 5 | [`docs/04-slices.md`](./docs/04-slices.md) | Quatro slices independentes (S1–S4) com ACs, dependências e critérios de pronto. |
| 6 | [`docs/05-open-questions.md`](./docs/05-open-questions.md) | Pendências assumidas conscientemente e débitos para investigação futura. |
| 7 | [`docs/06-glossary.md`](./docs/06-glossary.md) | Termos: camada, subagent, panorama, AC, runner, gate, etc. |
| 8 | [`docs/07-parallel-execution.md`](./docs/07-parallel-execution.md) | Guia operacional pra executar as slices em paralelo: ownership de arquivos, kickoff prompts, regras de concorrência. |

A ordem é cumulativa. Quem entra fresco pode parar em `02-decisions.md` para o contexto suficiente; quem vai executar uma slice precisa de `03-target-structure.md` + `04-slices.md` + `07-parallel-execution.md`.

## Como continuar

Esta documentação foi projetada para **sobreviver a um reset de contexto** e suportar **execução paralela** das slices por agentes independentes.

1. **Reler** [`docs/00-overview.md`](./docs/00-overview.md) e [`docs/02-decisions.md`](./docs/02-decisions.md) para reentrar no contexto.
2. **Escolher uma slice** em [`docs/04-slices.md`](./docs/04-slices.md). S1 não tem dependências; S2 depende de S1; S3 e S4 podem rodar em paralelo após S2.
3. **Antes de escrever código**, conferir [`docs/05-open-questions.md`](./docs/05-open-questions.md) — algumas decisões pequenas foram deferidas para o momento da implementação.
4. **Executar** a slice respeitando as ACs declaradas. Cada slice deve ser uma vertical thin — entrega valor end-to-end mesmo isolada das outras.

## Idioma

- **Esta documentação de planejamento**: PT-BR. Onboarding pessoal do dono.
- **README, CHANGELOG, user-help do template final**: PT-BR. Cliente lê.
- **Workflow internals, conventions, prompts de agentes**: EN. Padrão de mercado, runners se dão melhor.
