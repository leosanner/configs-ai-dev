.PHONY: help lint typecheck test secret-scan review wire-runners clean

help: ## Lista targets disponíveis
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

lint: ## Executa linter da stack (configure abaixo)
	@echo "preencha: comando de lint no Makefile (target lint)"; exit 1

typecheck: ## Executa typechecker da stack (configure abaixo)
	@echo "preencha: comando de typecheck no Makefile (target typecheck)"; exit 1

test: ## Executa testes; deve emitir .reports/test-results.{xml,json}
	@echo "preencha: comando de test no Makefile (target test)"; exit 1

secret-scan: ## Varre o repositório por secrets com gitleaks
	@mkdir -p .reports
	gitleaks detect --no-banner --report-path=.reports/gitleaks.json

review: ## Orquestra review local (Camadas 2–4)
	@./scripts/review.sh $(PR)

wire-runners: ## Cria symlinks .claude/.cursor/.codex → .agents/skills/<runner>
	@set -e; \
	for runner in claude cursor codex; do \
		mkdir -p .$$runner; \
		ln -sfn "$$(pwd)/.agents/skills/$$runner" .$$runner/skills; \
		echo "wired .$$runner/skills -> .agents/skills/$$runner"; \
	done

clean: ## Remove artefatos locais (.reports, .reviews)
	rm -rf .reports .reviews
