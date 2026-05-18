# Labels

Vocabulário de labels usado pela Camada 3 e gatilhos da Camada 4.

## Área (ativos no v1)

| Label | Subagent |
|-------|----------|
| `area:auth` | `auth` |
| `area:db` | `db` |
| `area:architecture` | `architecture` |

## Área (exemplos — comentados no GitHub)

```yaml
# area:performance — latência, bundle size
# area:ux — acessibilidade, copy
# area:public-read — endpoints públicos sem auth
```

## Risco (Camada 4)

| Label | Efeito |
|-------|--------|
| `area:auth` | Human review required |
| `area:secrets` | Human review required |
| `area:migrations` | Human review required |
| `area:public-read` | Human review required |
| `risk:high` | Human review required |
