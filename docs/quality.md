# Quality metrics

Snapshot persistido de métricas estruturais. Updates via proposta em `.reviews/*-quality-proposal.md` — humano aprova antes de editar este arquivo.

## Schema (`scripts/quality-scan.sh`)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `summary.totalFiles` | int | Arquivos no ref |
| `summary.filesOver1000` | int | Arquivos com >1000 linhas |
| `summary.todos` | int | Arquivos com TODO/FIXME |
| `summary.godClasses` | int | Placeholder v1 (0) |
| `summary.avgCyclomaticComplexity` | float | Placeholder v1 (0) |
| `files[]` | array | Top 20 por linhas: `{path, lines}` |

## Glossário

- **godClasses** — classes com responsabilidades demais (futuro).
- **avgCyclomaticComplexity** — média de complexidade ciclomática (futuro).

## Histórico

| Data | totalFiles | filesOver1000 | todos |
|------|------------|---------------|-------|
