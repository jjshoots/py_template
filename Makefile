# Parameters
CURL := $(shell command -v curl 2> /dev/null)
POETRY := $(shell command -v poetry 2> /dev/null)
PRECOMMIT := $(shell command -v pre-commit 2> /dev/null)
MKFILEPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
DIRNAME := $(notdir $(CURDIR))

# Default command when `make` is called
.DEFAULT_GOAL := help

# The main help
.PHONY: help
help:
	@echo "Please use 'make <target>', where <target> is one of"
	@echo ""
	@echo "  check       Verify all required tools are installed"
	@echo "  init        Initialize a new project using Poetry"
	@echo "  install     Install packages and prepare environment"
	@echo "  lock        Generate requirements.txt and poetry.lock"
	@echo "  test        Run tests with pytest"
	@echo ""
	@echo "Check the Makefile for detailed implementation."

# Ensure required tools are available
.PHONY: check
check:
	@echo "Checking for required tools..."
	@if [ -z $(CURL) ]; then echo "Error: curl is not installed."; exit 2; fi
	@if [ -z $(POETRY) ]; then echo "Error: Poetry is not installed."; exit 2; fi
	@echo "All checks passed."

# Initialize the project
.PHONY: init
init: check
	@echo "Initializing project with Poetry..."
	$(POETRY) new $(DIRNAME)
	mv $(DIRNAME) temp_dir
	mv temp_dir/* ./
	rmdir temp_dir
	rm -f README.rst
	mkdir -p src
	echo 'if __name__ == "__main__":\n    pass' > src/main.py
	touch .env README.md
	echo "# Project: $(DIRNAME)" > README.md
	$(CURL) -sSf https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore -o .gitignore
	git init -b main
	mkdir -p .github/workflows
	mv github_actions/* .github/workflows/
	rmdir github_actions
	$(POETRY) add --group dev pytest pre-commit
	$(MAKE) install

# Install dependencies
.PHONY: install
install: check
	@echo "Installing project dependencies..."
	$(POETRY) install
	. $$($(POETRY) env info --path)/bin/activate && pre-commit install

# Lock dependencies and generate requirements.txt
.PHONY: lock
lock: check
	@echo "Locking dependencies..."
	$(POETRY) lock
	$(POETRY) export -f requirements.txt --output requirements.txt

# Run tests
.PHONY: test
test: check
	@echo "Running tests..."
	$(POETRY) run pytest tests -vvv
