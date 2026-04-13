# indexion development Makefile

SHELL := /bin/bash
PLUGIN_DIR := $(CURDIR)/packages/vscode-plugin

.PHONY: dev-vsc-plugin
dev-vsc-plugin: ## Build native binary + plugin, then launch VSCode dev instance
	moon build --target native
	cd $(PLUGIN_DIR) && bun run build
	cd $(PLUGIN_DIR) && SKIP_BUILD=1 bun run dev
