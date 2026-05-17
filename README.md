# workflow-setup

Repositório de **planejamento** para um template de processo de trabalho com agentes de IA, agnóstico de runner (Cursor, Claude Code, Codex, etc.) e de stack.

> Status atual: **planejamento**. O conteúdo do template (`template/`) ainda **não foi implementado** — este repositório, por enquanto, contém apenas a documentação das decisões e do plano, capturadas durante uma sessão de conversa.

## Objetivo

Quando estiver pronto, o template servirá como ponto de partida para projetos novos. Cada projeto novo herda:

- Um arquivo `AGENTS.md` raiz que orienta qualquer agente.
- Um diretório `.agent/` com skills, rules e prompts (neutro entre runners).
- Um diretório `docs/` com a documentação tradicional (arquitetura, decisões, processo) já organizada.
- Scripts agnósticos (`review.sh`, `quality-scan.sh`, `next-steps.sh`).
- Templates para PRDs, Proposals, ADRs.

A inspiração e fonte primária de princípios é o projeto real `somos-oceano` (ver `reference/somos-oceano-mapping.md`).

## Como ler este repositório

Os documentos abaixo estão numerados na ordem em que fazem sentido ler:

| # | Arquivo | Para que serve |
|---|---|---|
| 0 | Este `README.md` | Entry point. Você está aqui. |
| 1 | [`docs/01-context-and-goals.md`](./docs/01-context-and-goals.md) | Contexto, objetivos, audiência, princípios destilados. |
| 2 | [`docs/02-decisions.md`](./docs/02-decisions.md) | Decisões fechadas durante a conversa, com justificativa. |
| 3 | [`docs/03-target-structure.md`](./docs/03-target-structure.md) | Árvore final do template + mudanças vs `somos-oceano`. |
| 4 | [`docs/04-content-plan.md`](./docs/04-content-plan.md) | Esboço do conteúdo de cada arquivo do template. |
| 5 | [`docs/05-open-questions.md`](./docs/05-open-questions.md) | Decisões ainda em aberto. |
| 6 | [`docs/06-implementation-order.md`](./docs/06-implementation-order.md) | Ordem sugerida de implementação. |
| — | [`reference/somos-oceano-mapping.md`](./reference/somos-oceano-mapping.md) | Mapeamento entre o projeto real e o template. |

## Como continuar

Esta documentação foi pensada para sobreviver a um reset de contexto. Quando voltar ao trabalho, o caminho sugerido é:

1. **Reler** `docs/01-context-and-goals.md` e `docs/02-decisions.md` para reentrar no contexto.
2. **Verificar pendências** em `docs/05-open-questions.md` — fechar as que ainda fazem sentido.
3. **Escolher uma peça** de `docs/06-implementation-order.md` (1ª na ordem é `AGENTS.md`).
4. **Aprofundar** o conteúdo dessa peça em `docs/04-content-plan.md` antes de implementar.
5. **Implementar** dentro de `template/<caminho>/` (criar `template/` quando começar a implementação).

## Idioma

- Esta documentação de planejamento: **português** (PT-BR), porque é onboarding pessoal do dono.
- O conteúdo final do template (quando implementado): seguirá a política do `somos-oceano` — docs internos em **inglês**, docs cliente (README, CHANGELOG, user-help) em **PT-BR**.
