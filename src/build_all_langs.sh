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
  
  LANG_MODE=$(echo "$lang_info" | jq -r '.lang_mode')
  LANG_CODE=$(echo "$lang_info" | jq -r '.lang_pack_code')
  INPUT_METHOD_INSTALL=$(echo "$lang_info" | jq -r '.input_method_install')
  CONFIG_IBUS_RIME=$(echo "$lang_info" | jq -r '.config_ibus_rime')
  TIMEZONE=$(echo "$lang_info" | jq -r '.timezone')

  # Update environment variables in args.sh using unified delimiter
  sed -i "s|^export LANG_MODE=\".*\"|export LANG_MODE=\"${LANG_MODE}\"|" args.sh
  sed -i "s|^export LANG_PACK_CODE=\".*\"|export LANG_PACK_CODE=\"${LANG_CODE}\"|" args.sh
  sed -i "s|^export INPUT_METHOD_INSTALL=\".*\"|export INPUT_METHOD_INSTALL=\"${INPUT_METHOD_INSTALL}\"|" args.sh
  sed -i "s|^export CONFIG_IBUS_RIME=\".*\"|export CONFIG_IBUS_RIME=\"${CONFIG_IBUS_RIME}\"|" args.sh
  sed -i "s|^export TIMEZONE=\".*\"|export TIMEZONE=\"${TIMEZONE}\"|" args.sh
  sed -i "s|^export CONFIG_WEATHER_LOCATION=\".*\"|export CONFIG_WEATHER_LOCATION=\"${CONFIG_WEATHER_LOCATION}\"|" args.sh
  sed -i "s|^export CONFIG_INPUT_METHOD=\".*\"|export CONFIG_INPUT_METHOD=\"${CONFIG_INPUT_METHOD}\"|" args.sh

  echo "================================================="
  echo "[INFO] Starting build -> LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE}"
  echo "[INFO] Input method: ${INPUT_METHOD_INSTALL}, Ibus Rime: ${CONFIG_IBUS_RIME}"
  echo "[INFO] Timezone: ${TIMEZONE}"
  echo "================================================="


  # Initialize retry parameters
  MAX_RETRIES=3
  attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    echo "[INFO] Build attempt $attempt for LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE}"
    
    if ./build.sh; then
      echo "[INFO] Build succeeded for LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE} on attempt $attempt."
      break
    else
      echo "[WARNING] Build failed for LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE} on attempt $attempt."
      if [ $attempt -lt $MAX_RETRIES ]; then
        echo "[INFO] Retrying build for LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE}..."
        attempt=$((attempt + 1))
      else
        echo "[ERROR] Build failed after $MAX_RETRIES attempts for LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE}."
        echo "[ERROR] Stopping build process and waiting for manual intervention."
        sleep 99999999
      fi
    fi
  done
done

echo "[INFO] All build tasks have been completed."