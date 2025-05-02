set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

if [ "$FIREFOX_PROVIDER" == "none" ]; then
    print_ok "We don't need to install firefox, please check the config file"
elif [ "$FIREFOX_PROVIDER" == "deb" ]; then
    print_ok "Adding Mozilla Firefox PPA"
    wait_network
    apt install $INTERACTIVE software-properties-common
    add-apt-repository -y ppa:mozillateam/ppa
    if [ -n "$FIREFOX_MIRROR" ]; then
        print_ok "Replace ppa.launchpadcontent.net with $FIREFOX_MIRROR to get faster download speed"
        sed -i "s/ppa.launchpadcontent.net/$FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).list
    fi
    cat << EOF > /etc/apt/preferences.d/mozilla-firefox
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 1:1snap*
Pin-Priority: -1
EOF
    chown root:root /etc/apt/preferences.d/mozilla-firefox
    judge "Add Mozilla Firefox PPA"

    print_ok "Updating package list to refresh firefox package cache"
    apt update
    judge "Update package list"

    print_ok "Installing Firefox and locale package $FIREFOX_LOCALE_PACKAGE from PPA: $FIREFOX_MIRROR"
    apt install $INTERACTIVE firefox $FIREFOX_LOCALE_PACKAGE --no-install-recommends
    judge "Install Firefox"
elif [ "$FIREFOX_PROVIDER" == "flatpak" ]; then
    print_ok "Installing firefox from flathub..."
    flatpak install -y flathub org.mozilla.firefox
    judge "Install firefox from flathub"
elif [ "$FIREFOX_PROVIDER" == "snap" ]; then
    print_ok "Installing firefox from snap..."
    snap install firefox
    judge "Install firefox from snap"
else
    print_error "Unknown firefox provider: $FIREFOX_PROVIDER"
    print_error "Please check the config file"
    exit 1
fi