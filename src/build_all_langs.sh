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
  echo "[ERROR] Invalid argument. Use '--langs all' or '--langs fast'."
  exit 1
fi

# -----------------------------------------------------------------------------
# 2. Define language modes and their corresponding language pack codes
# -----------------------------------------------------------------------------
# Full set of languages
ALL_LANG_MODES=(     "en_US" "zh_CN" "zh_TW" "zh_HK" "ja_JP" "ko_KR" "vi_VN" "th_TH" "de_DE" "fr_FR" "es_ES" "ru_RU" "it_IT" "pt_PT" "pt_BR" "ar_SA" "nl_NL" "sv_SE" "pl_PL" "tr_TR")
ALL_LANG_PACK_CODES=("en"    "zh"     "zh"   "zh"    "ja"    "ko"    "vi"    "th"    "de"    "fr"    "es"    "ru"    "it"    "pt"    "pt"    "ar"    "nl"    "sv"    "pl"    "tr")

# Subset for 'fast' builds
FAST_LANG_MODES=(     "en_US" "zh_CN")
FAST_LANG_PACK_CODES=("en"    "zh")

# Based on the chosen build mode, select which arrays to iterate over
if [[ "$BUILD_MODE" == "fast" ]]; then
  LANG_MODES=("${FAST_LANG_MODES[@]}")
  LANG_PACK_CODES=("${FAST_LANG_PACK_CODES[@]}")
else
  LANG_MODES=("${ALL_LANG_MODES[@]}")
  LANG_PACK_CODES=("${ALL_LANG_PACK_CODES[@]}")
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
for i in "${!LANG_MODES[@]}"; do
  LANG_MODE="${LANG_MODES[$i]}"
  LANG_CODE="${LANG_PACK_CODES[$i]}"

  # Update environment variables in args.sh
  sed -i "s/^export LANG_MODE=\".*\"/export LANG_MODE=\"${LANG_MODE}\"/" args.sh
  sed -i "s/^export LANG_PACK_CODE=\".*\"/export LANG_PACK_CODE=\"${LANG_CODE}\"/" args.sh

  echo "================================================="
  echo "[INFO] Starting build -> LANG_MODE: ${LANG_MODE}, LANG_CODE: ${LANG_CODE}"
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
