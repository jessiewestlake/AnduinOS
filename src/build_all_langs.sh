#!/bin/bash
#
# Usage examples:
#   ./build_all_langs.sh                 # By default, builds for all languages
#   ./build_all_langs.sh --langs fast    # Builds only en_US and zh_CN
#   ./build_all_langs.sh --langs all     # Builds for all languages
#

set -e                  # Exit immediately if any command returns a non-zero status
set -o pipefail         # If any command in a pipeline fails, the entire pipeline fails
set -u                  # Treat unset variables as an error

# -----------------------------------------------------------------------------
# 1. Parse input argument for build mode
# -----------------------------------------------------------------------------
BUILD_MODE="all"  # Default mode is 'all'

# If the user passes in '--langs ...'
if [[ "${1:-}" == "--langs" ]]; then
  if [[ "${2:-}" == "fast" ]]; then
    BUILD_MODE="fast"
    echo "[INFO] Building only for 'en_US' and 'zh_CN' languages."
  elif [[ "${2:-}" == "all" ]]; then
    BUILD_MODE="all"
    echo "[INFO] Building for all languages."
  else
    echo "[ERROR] Invalid value for '--langs'. Use 'all' or 'fast'."
    exit 1
  fi
else
  echo "[INFO] No arguments provided, defaulting to building for all languages."
fi

# -----------------------------------------------------------------------------
# 2. Load language configuration from JSON file
# -----------------------------------------------------------------------------
LANGUAGES_JSON="languages.json"

if [[ ! -f "$LANGUAGES_JSON" ]]; then
  echo "[ERROR] Language configuration file $LANGUAGES_JSON does not exist."
  exit 1
fi

# Check if jq is installed, install if not
if ! command -v jq &> /dev/null; then
  echo "[INFO] Installing jq for JSON parsing..."
  sudo apt-get update && sudo apt-get install -y jq
fi

# Build array of languages based on the selected mode
if [[ "$BUILD_MODE" == "fast" ]]; then
  # Just select English and Chinese for fast mode
  selected_languages=$(jq -c '[.[] | select(.lang_mode == "en_US" or .lang_mode == "zh_CN")]' "$LANGUAGES_JSON")
else
  # Use all languages for full mode
  selected_languages=$(jq -c '.' "$LANGUAGES_JSON")
fi

# -----------------------------------------------------------------------------
# 3. Cleanup old files
# -----------------------------------------------------------------------------
echo "[INFO] Removing old distribution files..."
sudo rm -rf ./dist/*

# -----------------------------------------------------------------------------
# 4. Check for required files
# -----------------------------------------------------------------------------
if [[ ! -f "args.sh" || ! -f "build.sh" ]]; then
  echo "[ERROR] args.sh or build.sh does not exist."
  exit 1
fi

# -----------------------------------------------------------------------------
# 5. Build loop for selected languages with retry mechanism
# -----------------------------------------------------------------------------
# Get the count of languages from the selected_languages JSON array
lang_count=$(echo "$selected_languages" | jq '. | length')

for ((i=0; i<lang_count; i++)); do
  # Extract language information from JSON
  lang_info=$(echo "$selected_languages" | jq -c ".[$i]")
  
  # Display summary of the current language for logging
  LANG_MODE=$(echo "$lang_info" | jq -r '.lang_mode')
  echo "================================================="
  echo "[INFO] Starting build -> LANG_MODE: ${LANG_MODE}"
  echo "Current language configuration:"
  echo "$lang_info" | jq '.'
  echo "================================================="
  
  # Dynamically update all fields in args.sh
  # Get all keys from the current language configuration
  keys=$(echo "$lang_info" | jq -r 'keys[]')
  
  # For each key, update the corresponding environment variable in args.sh
  for key in $keys; do
    # Convert key to uppercase for environment variable naming
    env_var=$(echo "$key" | tr '[:lower:]' '[:upper:]')
    # Get the value and escape any special characters
    value=$(echo "$lang_info" | jq -r --arg k "$key" '.[$k]')
    # Replace the line in args.sh
    escaped_value=$(echo "$value" | sed 's/[\/&]/\\&/g')
    sed -i "s|^export ${env_var}=\".*\"|export ${env_var}=\"${escaped_value}\"|" args.sh
  done

  # Initialize retry parameters
  MAX_RETRIES=3
  attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    echo "[INFO] Build attempt $attempt for LANG_MODE: ${LANG_MODE}"
    
    if ./build.sh; then
      echo "[INFO] Build succeeded for LANG_MODE: ${LANG_MODE} on attempt $attempt."
      break
    else
      echo "[WARNING] Build failed for LANG_MODE: ${LANG_MODE} on attempt $attempt."
      if [ $attempt -lt $MAX_RETRIES ]; then
        echo "[INFO] Retrying build for LANG_MODE: ${LANG_MODE}..."
        attempt=$((attempt + 1))
      else
        echo "[ERROR] Build failed after $MAX_RETRIES attempts for LANG_MODE: ${LANG_MODE}."
        echo "[ERROR] Stopping build process and waiting for manual intervention."
        sleep 99999999
      fi
    fi
  done
done

echo "[INFO] All build tasks have been completed."