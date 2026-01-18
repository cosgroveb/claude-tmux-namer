.PHONY: install uninstall

PLUGIN_NAME := tmux-window-namer
MARKETPLACE_NAME := claude-tmux-namer

install:
	@echo "Adding marketplace..."
	claude plugin marketplace add "$(shell pwd)"
	@echo "Installing plugin..."
	claude plugin install $(PLUGIN_NAME)@$(MARKETPLACE_NAME)
	@echo "Done. The plugin will rename your tmux window after each Claude response."

uninstall:
	@echo "Uninstalling plugin..."
	claude plugin uninstall $(PLUGIN_NAME)
	@echo "Removing marketplace..."
	claude plugin marketplace remove $(MARKETPLACE_NAME)
	@echo "Done."
