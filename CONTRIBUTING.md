# Contribuindo

## Fluxo

1. Abra um PR com `PRD:` ou `Proposal:` no body (veja `.github/PULL_REQUEST_TEMPLATE.md`).
2. Garanta CI verde (`make lint`, `make typecheck`, `make test`, `make secret-scan`).
3. Rode `make review PR=<n>` localmente antes de pedir merge (quando Camadas 2–4 estiverem implementadas).
4. Adicione entrada em `CHANGELOG.md` sob `## [Não lançado]`.

## Commits

Use mensagens claras em português ou inglês, consistentes com o histórico do repositório.

## CHANGELOG

Siga [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). Categorias: Adicionado, Alterado, Corrigido, Removido.
