set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing gnome software and flatpak support"
sudo apt install -y \
    flatpak \
    gnome-software \
    gnome-software-plugin-flatpak \
    gnome-software-plugin-deb --no-install-recommends
judge "Install gnome software with flatpak support"

print_ok "Installing gnome software plugins..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
judge "Install gnome software plugins"

# export FLATPAK_FIREFOX="false"
if [ "$FLATPAK_FIREFOX" = "true" ]; then
    print_ok "Installing firefox from flathub..."
    flatpak install -y flathub org.mozilla.firefox
    judge "Install firefox from flathub"
else
    print_ok "No need to install flatpak firefox, please check the config file"
fi
