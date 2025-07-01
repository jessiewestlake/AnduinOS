#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
TARGET_FILE="/root/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/panelPositions.js"

# --- Ensure target exists ---
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[ERROR] Target file not found: $TARGET_FILE" >&2
    exit 1
fi

print_ok "Applying new panel layout patch"
sed -i "/export const defaults = \[/,/\];/c\\
\/\/ AnduinOS custom default panel layout\\
export const defaults = [\\
  { element: LEFT_BOX, visible: true, position: STACKED_TL },\\
  { element: CENTER_BOX, visible: true, position: CENTERED },\\
  { element: TASKBAR, visible: true, position: CENTERED },\\
  { element: RIGHT_BOX, visible: true, position: STACKED_BR },\\
  { element: SYSTEM_MENU, visible: true, position: STACKED_BR },\\
  { element: DATE_MENU, visible: true, position: STACKED_BR },\\
  { element: DESKTOP_BTN, visible: true, position: STACKED_BR },\\
];" \
  "$TARGET_FILE"
judge "Apply new panel layout patch"

# --- Multiline search and replacement blocks ---
# read -r -d '' FIND_BLOCK <<'EOF'
# export const defaults = [
#   { element: SHOW_APPS_BTN, visible: true, position: STACKED_TL },
#   { element: ACTIVITIES_BTN, visible: false, position: STACKED_TL },
#   { element: LEFT_BOX, visible: true, position: STACKED_TL },
#   { element: TASKBAR, visible: true, position: STACKED_TL },
#   { element: CENTER_BOX, visible: true, position: STACKED_BR },
#   { element: RIGHT_BOX, visible: true, position: STACKED_BR },
#   { element: DATE_MENU, visible: true, position: STACKED_BR },
#   { element: SYSTEM_MENU, visible: true, position: STACKED_BR },
#   { element: DESKTOP_BTN, visible: true, position: STACKED_BR },
# ]
# EOF

# read -r -d '' REPLACE_BLOCK <<'EOF'
# // AnduinOS custom default panel layout
# export const defaults = [
#   { element: LEFT_BOX, visible: true, position: STACKED_TL },
#   { element: CENTER_BOX, visible: true, position: CENTERED },
#   { element: TASKBAR, visible: true, position: CENTERED },
#   { element: RIGHT_BOX, visible: true, position: STACKED_BR },
#   { element: SYSTEM_MENU, visible: true, position: STACKED_BR },
#   { element: DATE_MENU, visible: true, position: STACKED_BR },
#   { element: DESKTOP_BTN, visible: true, position: STACKED_BR },
# ];
# EOF

# # --- Perform replacement ---
# print_ok "Applying panel layout patch"
# sudo perl -0777 -i -Input Methodpe "s/\Q$FIND_BLOCK\E/$REPLACE_BLOCK/m" "$TARGET_FILE"
# judge "Panel layout replacement"

# --- Verify success ---
if ! grep -q "AnduinOS custom default panel layout" "$TARGET_FILE"; then
    echo "[ERROR] Replacement verification failed" >&2
    exit 1
fi
print_ok "Patch applied successfully"
