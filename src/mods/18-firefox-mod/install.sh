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
    if [ -n "$BUILD_FIREFOX_MIRROR" ]; then
        print_ok "Replace ppa.launchpadcontent.net with $BUILD_FIREFOX_MIRROR to get faster download speed"
        sed -i "s/ppa.launchpadcontent.net/$BUILD_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
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

    print_ok "Installing Firefox and locale package $FIREFOX_LOCALE_PACKAGE from PPA: $BUILD_FIREFOX_MIRROR"
    apt install $INTERACTIVE firefox $FIREFOX_LOCALE_PACKAGE --no-install-recommends
    judge "Install Firefox"

    # If both Build mirror and Live mirror are set, replace Build mirror with Live mirror
    if [ -n "$BUILD_FIREFOX_MIRROR" ] && [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replace $BUILD_FIREFOX_MIRROR with $LIVE_FIREFOX_MIRROR..."
        sed -i "s/$BUILD_FIREFOX_MIRROR/$LIVE_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
        judge "Replace BUILD_FIREFOX_MIRROR with LIVE_FIREFOX_MIRROR"
    # If only live mirror is set, replace ppa.launchpadcontent.net with live mirror
    elif [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replace ppa.launchpadcontent.net with $LIVE_FIREFOX_MIRROR..."
        sed -i "s/ppa.launchpadcontent.net/$LIVE_FIREFOX_MIRROR/g" \
            /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(lsb_release -sc).sources
        judge "Replace ppa.launchpadcontent.net with LIVE_FIREFOX_MIRROR"
    else
        print_warn "No BUILD_FIREFOX_MIRROR or LIVE_FIREFOX_MIRROR set, skip replacing mirror"
    fi
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