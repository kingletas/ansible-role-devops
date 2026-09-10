# ansible-role-devops — provision a machine with DevOps tooling
#
# Run `make` with no arguments for the list.

SHELL       := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@echo
	@echo "  ansible-role-devops — provision a machine with DevOps tooling"
	@echo
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo

# --- setup ------------------------------------------------------------------

.PHONY: collections
collections: ## Install the Ansible collections the role needs
	ansible-galaxy collection install -r requirements.yml

# --- checks -----------------------------------------------------------------

.PHONY: yamllint
yamllint: ## Lint every YAML file
	yamllint .

.PHONY: ansible-lint
ansible-lint: ## Lint the role at the production profile
	@scripts/link-role
	ansible-lint

.PHONY: syntax
syntax: ## Syntax-check the example playbooks
	@scripts/syntax-check

.PHONY: converge
converge: ## Converge, re-run and verify the role in a container (needs Docker and Molecule)
	@scripts/link-role
	molecule test

.PHONY: check
check: yamllint ansible-lint syntax ## Everything a commit has to pass
	@echo
	@echo "  yamllint, ansible-lint and the syntax check pass"
