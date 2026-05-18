# Configuração do GitHub

## Branch protection (manual)

O GitHub não permite definir branch protection via arquivo no repositório. Configure em:

1. **Settings** → **Branches** → **Branch protection rules** → **Add rule**
2. Branch name pattern: `main`
3. Marque:
   - **Require a pull request before merging**
   - **Require status checks to pass before merging** — selecione o check do workflow `CI` / job `static`
   - **Require review from Code Owners** (opcional, após editar `CODEOWNERS`)
4. **Restrict who can push to matching branches** (recomendado para `main`)

## CI

O workflow `.github/workflows/ci.yml` executa `make lint`, `make typecheck`, `make test` e `make secret-scan` em todo PR e push em `main`.

Artifacts `test-results-<sha>` e `gitleaks-<sha>` ficam disponíveis para a Camada 2 (AC pass).
