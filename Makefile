# Directory variables
SRC_DIR = src
INSTALL_DIR = /usr/local/sbin

# List of scripts to install (dynamically get all files in the src directory)
SCRIPTS = $(wildcard $(SRC_DIR)/*)

# Default target
all:
	@echo "Default make does not perform installation. Use 'make install' to install scripts."
	
# Install target
install:
	@echo "Installing scripts to $(INSTALL_DIR)..."
	@for script in $(SCRIPTS); do \
		script_name=$$(basename $$script); \
		echo "Installing $$script_name..."; \
		install -m 755 $$script $(INSTALL_DIR)/$$script_name; \
	done

# Uninstall target
uninstall:
	@echo "Removing scripts from $(INSTALL_DIR)..."
	@for script in $(SCRIPTS); do \
		script_name=$$(basename $$script); \
		echo "Removing $$script_name..."; \
		rm -f $(INSTALL_DIR)/$$script_name; \
	done

# Clean target
clean:
	@echo "Clean target does nothing for now..."

# Phony targets
.PHONY: all install uninstall clean

