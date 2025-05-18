#!/bin/bash
#==========================
# Set up the environment
#==========================
set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
export DEBIAN_FRONTEND=noninteractive
export LATEST_VERSION="1.3.1"
export CODE_NAME="plucky"
export OS_ID="AnduinOS"
export CURRENT_VERSION=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d "=" -f 2)

#==========================
# Color
#==========================
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[  OK  ]${Font}"
ERROR="${Red}[FAILED]${Font}"
WARNING="${Yellow}[ WARN ]${Font}"

#==========================
# Print Colorful Text
#==========================
function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

function print_error() {
  echo -e "${ERROR} ${Red} $1 ${Font}"
}

function print_warn() {
  echo -e "${WARNING} ${Yellow} $1 ${Font}"
}

#==========================
# Judge function
#==========================
function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 succeeded"
    sleep 0.2
  else
    print_error "$1 failed"
    exit 1
  fi
}

function ensureCurrentOsAnduinOs() {
    # Ensure the current OS is AnduinOS
    if ! grep -q "DISTRIB_ID=AnduinOS" /etc/lsb-release; then
        print_error "This script can only be run on AnduinOS."
        exit 1
    fi
}

function upgrade_130_to_131() {
    print_ok "Upgrading from 1.3.0 to 1.3.1..."
    sudo apt update
    sudo apt install -y \
        gstreamer1.0-libav \
        gnome-browser-connector \
        gnome-control-center-faces \
        gnome-keyring-pkcs11 \
        gvfs-backends \
        orca \
        wsdd \
        libpam-gnome-keyring \
        libpam-sss \
        libpam-fprintd \
        --no-install-recommends

    fonts_config="https://gitlab.aiursoft.cn/anduin/anduinos/-/raw/1.4/src/mods/15-fonts-mod/local.conf?ref_type=heads"
    sudo wget -O /etc/fonts/local.conf $fonts_config
    fc-cache -f
    judge "Upgrade from 1.3.0 to 1.3.1 completed"
}

function install_spg() {
    print_ok "Downloading software-properties-gtk..."
    sudo apt install -y \
        python3-dateutil \
        gir1.2-handy-1 \
        libgtk3-perl \
        --no-install-recommends
    judge "Install python3-dateutil"

    sudo apt-get download "software-properties-gtk"
    judge "Download software-properties-gtk"

    DEB_FILE=$(ls *.deb)
    print_ok "Found $DEB_FILE"
    sudo chown $USER:$USER "$DEB_FILE"

    print_ok "Extracting $DEB_FILE..."
    mkdir original
    dpkg-deb -R "$DEB_FILE" original
    judge "Extract $DEB_FILE"

    print_ok "Patching control file..."
    sed -i \
    '/^Depends:/s/, *ubuntu-pro-client//; /^Depends:/s/, *ubuntu-advantage-desktop-daemon//' \
    original/DEBIAN/control
    judge "Edit control file"

    MOD_DEB="modified.deb"

    print_ok "Repackaging $MOD_DEB..."
    dpkg-deb -b original "$MOD_DEB"
    judge "Repackage $MOD_DEB"

    print_ok "Cleaning up temp folder..."
    rm -rf original

    print_ok "Installing $MOD_DEB..."
    sudo dpkg -i "$MOD_DEB"
    judge "Install $MOD_DEB"

    print_ok "Cleaning up $MOD_DEB and $DEB_FILE..."
    rm -f "$MOD_DEB"
    rm -f "$DEB_FILE"
    judge "Clean up $MOD_DEB and $DEB_FILE"

    FILE=/usr/lib/python3/dist-packages/softwareproperties/gtk/SoftwarePropertiesGtk.py

    print_ok "Patching $FILE... to disable Ubuntu Pro"
    sudo cp "$FILE" "${FILE}.bak"
    sudo sed -i '/^from \.UbuntuProPage import UbuntuProPage$/d' "$FILE"
    sudo sed -i '/^[[:space:]]*def init_ubuntu_pro/,/^[[:space:]]*$/d' "$FILE"
    sudo sed -i '/^[[:space:]]*if is_current_distro_lts()/,/self.init_ubuntu_pro()/d' "$FILE"
    judge "Edit $FILE"

    print_ok "Marking software-properties-gtk as held..."
    sudo apt-mark hold software-properties-gtk
    judge "Mark software-properties-gtk as held"

}

function upgrade_131_to_132() {
    # If the flatpak remote is https://mirror.sjtu.edu.cn/flathub
    # Change it to sudo flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub

    # If flatpak installed
    if command -v flatpak &> /dev/null; then
      current_url=$(flatpak remotes --columns=name,url | awk '$1=="flathub"{print $2}')
      if [[ "$current_url" == *"https://mirror.sjtu.edu.cn/flathub"* ]]; then
          print_ok "Detected SJTU mirror for flathub. Switching to USTC mirror..."
          sudo flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
          print_ok "Switch completed."
      fi
    fi

    sudo apt update
    sudo apt install -y \
        vim \
        cracklib-runtime \
        power-profiles-daemon \
        --no-install-recommends
    judge "Install vim completed"

    apt list --installed | grep software-properties-gtk || install_spg
}


function applyLsbRelease() {

    # Update /etc/os-release
    sudo bash -c "cat > /etc/os-release <<EOF
PRETTY_NAME=\"AnduinOS $LATEST_VERSION\"
NAME=\"AnduinOS\"
VERSION_ID=\"$LATEST_VERSION\"
VERSION=\"$LATEST_VERSION ($CODE_NAME)\"
VERSION_CODENAME=$CODE_NAME
ID=ubuntu
ID_LIKE=debian
HOME_URL=\"https://www.anduinos.com/\"
SUPPORT_URL=\"https://github.com/Anduin2017/AnduinOS/discussions\"
BUG_REPORT_URL=\"https://github.com/Anduin2017/AnduinOS/issues\"
PRIVACY_POLICY_URL=\"https://www.ubuntu.com/legal/terms-and-policies/privacy-policy\"
UBUNTU_CODENAME=$CODE_NAME
EOF"

    # Update /etc/lsb-release
    sudo bash -c "cat > /etc/lsb-release <<EOF
DISTRIB_ID=AnduinOS
DISTRIB_RELEASE=$LATEST_VERSION
DISTRIB_CODENAME=$CODE_NAME
DISTRIB_DESCRIPTION=\"AnduinOS $LATEST_VERSION\"
EOF"

    # Update /etc/issue
    echo "AnduinOS ${LATEST_VERSION} \n \l
" | sudo tee /etc/issue

    # Update /usr/lib/os-release
    sudo cp /etc/os-release /usr/lib/os-release
}

function main() {
    print_ok "Current version is: ${CURRENT_VERSION}. Checking for updates..."

    # Ensure the current OS is AnduinOS
    ensureCurrentOsAnduinOs

    # Compare current version with latest version
    if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
        print_ok "Your system is already up to date. No update available."
        exit 0
    fi

    print_ok "This script will upgrade your system to version ${LATEST_VERSION}..."
    print_ok "Please press CTRL+C to cancel... Countdown will start in 5 seconds..."
    sleep 5

    # Run necessary upgrades based on current version
    case "$CURRENT_VERSION" in
          "1.3.0")
              upgrade_130_to_131
              ;;
          "1.3.1")
              print_ok "Your system is already up to date. No update available."
              exit 0
              ;;
           *)
              print_error "Unknown current version. Exiting."
              exit 1
              ;;
    esac

    # Grammar sample:
    # case "$CURRENT_VERSION" in
    #     "1.0.2")
    #         upgrade_102_to_103
    #         upgrade_103_to_104
    #         ;;
    #     "1.0.3")
    #         upgrade_103_to_104
    #         ;;
    #     "1.0.4")
    #         print_ok "Your system is already up to date. No update available."
    #         exit 0
    #         ;;
    #     *)
    #         print_error "Unknown current version. Exiting."
    #         exit 1
    #         ;;
    # esac

    # Apply updates to lsb-release, os-release, and issue files
    applyLsbRelease
    print_ok "System upgraded successfully to version ${LATEST_VERSION}"
}

main