# Makefile —— AnduinOS build orchestrator
SHELL      := /usr/bin/env bash
.DEFAULT_GOAL := current

SRC_DIR    := src
CONFIG_DIR := config

.PHONY: all fast current clean check-env help

help:
	@echo "Usage:"
	@echo "  make          (or make current)   Build current language"
	@echo "  make all                          Build all languages"
	@echo "  make fast                         Build fast config languages"
	@echo "  make clean                        Remove build artifacts"
	@echo "  make check-env                   Validate environment"

check-env:
	@if [ "$$(id -u)" -eq 0 ]; then \
	  echo "Error: Do not run as root"; exit 1; \
	fi
	@if ! lsb_release -i | grep -qE "(Ubuntu|Debian|AnduinOS)"; then \
	  echo "Error: Unsupported OS — only Ubuntu, Debian or AnduinOS allowed"; exit 1; \
	fi

current: check-env
	@echo "[MAKE] Building current language..."
	@cd $(SRC_DIR) && ./build.sh

all: check-env
	@echo "[MAKE] Building ALL languages (all.json)..."
	@./build_all.sh -c $(CONFIG_DIR)/all.json

fast: check-env
	@echo "[MAKE] Building FAST languages (fast.json)..."
	@./build_all.sh -c $(CONFIG_DIR)/fast.json

clean:
	@echo "[MAKE] Cleaning build artifacts..."
	@rm -rf $(SRC_DIR)/dist/* $(SRC_DIR)/image
	@echo "[MAKE] Clean complete."
