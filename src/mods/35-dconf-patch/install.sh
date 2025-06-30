set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# dconf is a binary file. To apply default dconf to all users, we must:
# - First apply the dconf settings to root user
# - Then copy the dconf settings to /etc/skel
# - Then remove the dconf settings from root user

print_ok "Loading dconf settings"

print_ok "Exporting dbus session"
export $(dbus-launch)
judge "Export dbus session"

print_ok "Loading dconf settings for org.gnome"
dconf load /org/gnome/ < ./dconf.ini
judge "Load dconf settings for org.gnome"

# print_ok "Patching dconf settings for dash-to-panel"
# mkdir -p /etc/dconf/db/local.d
# tee /etc/dconf/db/local.d/11-dash-to-panel <<'EOF'
# [org/gnome/shell/extensions/dash-to-panel]
# panel-element-positions='{"0":[{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
# EOF
# judge "Patch dconf settings for dash-to-panel"

# print_ok "Locking dconf settings for dash-to-panel"
# mkdir -p /etc/dconf/db/local.d/locks
# tee /etc/dconf/db/local.d/locks/dash-to-panel-lock <<'EOF'
# /org/gnome/shell/extensions/dash-to-panel/panel-element-positions
# EOF
# judge "Lock dconf settings for dash-to-panel"

dconf write /org/gtk/settings/file-chooser/sort-directories-first true
dconf write /org/gnome/desktop/input-sources/xkb-options "@as []"
dconf write /org/gnome/desktop/input-sources/mru-sources "[('xkb', 'us')]"
judge "Load dconf settings"

print_ok "Patching global gdm3 dconf settings"
cp ./anduinos_text_smaller.png /usr/share/pixmaps/anduinos_text_smaller.png
cp ./greeter.dconf-defaults.ini /etc/gdm3/greeter.dconf-defaults
dconf update
judge "Patch global gdm3 dconf settings"

# IF CONFIG_INPUT_METHOD is not set, exit.
if [ -z "$CONFIG_INPUT_METHOD" ]; then
    print_error "Error: CONFIG_INPUT_METHOD is not set."
    exit 1
fi

print_ok "Configuring input sources from CONFIG_INPUT_METHOD"
dconf write /org/gnome/desktop/input-sources/sources "$CONFIG_INPUT_METHOD"
judge "Configure input sources"

# IF CONFIG_WEATHER_LOCATION is not set, exit.
if [ -z "$CONFIG_WEATHER_LOCATION" ]; then
    print_error "Error: CONFIG_WEATHER_LOCATION is not set."
    exit 1
fi

print_ok "Configuring weather location from CONFIG_WEATHER_LOCATION"
dconf write /org/gnome/shell/extensions/openweatherrefined/locs "$CONFIG_WEATHER_LOCATION"
judge "Configure weather location"

print_ok "Copying root's dconf settings to /etc/skel"
mkdir -p /etc/skel/.config/dconf
cp /root/.config/dconf/user /etc/skel/.config/dconf/user
judge "Copy root's dconf settings to /etc/skel"
