# SupportOps Analytics Platform — task runner
#
# Infra targets (up/down/db-shell) are live as of issue #1.
# Pipeline targets remain placeholders until their issues land.

# Load .env if present so targets can use the variables.
ifneq (,$(wildcard .env))
include .env
export
endif

.PHONY: help setup up down logs db-shell migrate import validate promote report test

help: ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

setup: ## Create .env from .env.example if missing
	@[ -f .env ] || (cp .env.example .env && echo "Created .env from .env.example")

up: setup ## Start PostgreSQL (Docker Compose)
	docker compose up -d
	@echo "PostgreSQL is starting on localhost:$(POSTGRES_PORT)"

down: ## Stop containers (keeps the data volume)
	docker compose down

logs: ## Tail PostgreSQL logs
	docker compose logs -f postgres

db-shell: ## Open a psql shell in the postgres container
	docker compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

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
