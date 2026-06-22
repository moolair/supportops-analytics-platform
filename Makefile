# SupportOps Analytics Platform — task runner
#
# PLACEHOLDER targets — real commands are wired up across issues #1–#9.
# Each target currently just announces intent so the workflow is documented.

.PHONY: help setup up down migrate import validate promote report test

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

setup: ## Install/prepare local dependencies (issue #1)
	@echo "TODO: setup — see issue #1"

up: ## Start Postgres + Metabase via Docker Compose (issue #1)
	@echo "TODO: docker compose up — see issue #1"

down: ## Stop containers (issue #1)
	@echo "TODO: docker compose down — see issue #1"

migrate: ## Apply SQL migrations (issue #2)
	@echo "TODO: run migrations — see issue #2"

import: ## Load a CSV into raw_tickets (issues #4, #13)
	@echo "TODO: import CSV — see issues #4 and #13"

validate: ## Run validation engine raw -> staging (issues #5, #6)
	@echo "TODO: validate — see issues #5 and #6"

promote: ## Promote validated rows into clean tickets (issue #7)
	@echo "TODO: promote — see issue #7"

report: ## Generate the data-quality report
	@echo "TODO: data-quality report"

test: ## Run Go tests
	@echo "TODO: go test ./..."
