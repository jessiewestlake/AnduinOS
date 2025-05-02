set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# dconf is a binary file. To apply default dconf to all users, we must:
# - First apply the dconf settings to root user
# - Then copy the dconf settings to /etc/skel
# - Then remove the dconf settings from root user

print_ok "Loading dconf settings"
export $(dbus-launch)

dconf load /org/gnome/ < ./dconf.ini
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
