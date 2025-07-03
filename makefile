# Makefile —— AnduinOS build orchestrator
SHELL         := /usr/bin/env bash
.DEFAULT_GOAL := current

SRC_DIR       := src
CONFIG_DIR    := config

# Auto-detect host architecture, can be overridden with TARGET_ARCH=<arch>
HOST_ARCH     := $(shell dpkg --print-architecture)
TARGET_ARCH   ?= $(HOST_ARCH)

# Base dependencies (architecture-independent)
BASE_DEPS := \
  binutils \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub2-common \
  mtools \
  dosfstools

# Architecture-specific dependencies
# x86/amd64: Requires BIOS boot support (grub-pc-bin) and UEFI support (grub-efi-amd64)
DEPS_amd64 := \
  grub-pc-bin \
  grub-efi-amd64

# ARM64: Requires only UEFI support (grub-efi-arm64)
DEPS_arm64 := \
  grub-efi-arm64

# Combined dependencies for target architecture
DEPS := $(BASE_DEPS) $(DEPS_$(TARGET_ARCH))

.PHONY: all fast current clean bootstrap help

help:
	@echo "Usage:"
	@echo "  make          (or make current)   Build current language"
	@echo "  make all                          Build all languages"
	@echo "  make fast                         Build fast config languages"
	@echo "  make clean                        Remove build artifacts"
	@echo "  make bootstrap                    Validate environment and deps"
	@echo ""
	@echo "Architecture Selection:"
	@echo "  TARGET_ARCH=amd64                 Build for x86_64 (default on amd64 hosts)"
	@echo "  TARGET_ARCH=arm64                 Build for ARM64 (default on arm64 hosts)"
	@echo "  Current target: $(TARGET_ARCH)"
	@echo ""
	@echo "Examples:"
	@echo "  make TARGET_ARCH=arm64            Build current language for ARM64"
	@echo "  make all TARGET_ARCH=amd64        Build all languages for x86_64"

bootstrap:
	@echo "[MAKE] Target architecture: $(TARGET_ARCH)"
	@if [ "$$(id -u)" -eq 0 ]; then \
	  echo "Error: Do not run as root"; \
	  exit 1; \
	fi
	@if ! lsb_release -i | grep -qE "(Ubuntu|Debian|Tuxedo|AnduinOS)"; then \
	  echo "Error: Unsupported OS — only Ubuntu, Debian, Tuxedo or AnduinOS allowed"; \
	  exit 1; \
	fi
	
	@# Validate target architecture
	@case "$(TARGET_ARCH)" in \
	  amd64|arm64) \
	    echo "[MAKE] Building for supported architecture: $(TARGET_ARCH)" ;; \
	  *) \
	    echo "Error: Unsupported architecture '$(TARGET_ARCH)'. Supported: amd64, arm64"; \
	    exit 1 ;; \
	esac

	@missing="" ; \
	for pkg in $(DEPS); do \
	  if ! dpkg -s $$pkg >/dev/null 2>&1; then \
	    missing="$$missing $$pkg"; \
	  fi; \
	done; \
	if [ -n "$$missing" ]; then \
	  echo "Missing packages for $(TARGET_ARCH):$$missing"; \
	  echo "Installing missing dependencies..."; \
	  sudo apt-get update && sudo apt-get install -y$$missing; \
	else \
	  echo "[MAKE] All required packages for $(TARGET_ARCH) are already installed."; \
	fi

current: bootstrap
	@echo "[MAKE] Building current language for $(TARGET_ARCH)..."
	@cd $(SRC_DIR) && TARGET_ARCH=$(TARGET_ARCH) ./build.sh

all: bootstrap
	@echo "[MAKE] Building ALL languages (all.json) for $(TARGET_ARCH)..."
	@TARGET_ARCH=$(TARGET_ARCH) ./build_all.sh -c $(CONFIG_DIR)/all.json

fast: bootstrap
	@echo "[MAKE] Building FAST languages (fast.json) for $(TARGET_ARCH)..."
	@TARGET_ARCH=$(TARGET_ARCH) ./build_all.sh -c $(CONFIG_DIR)/fast.json

clean:
	@echo "[MAKE] Cleaning build artifacts..."
	@./clean_all.sh
	@echo "[MAKE] Clean complete."
