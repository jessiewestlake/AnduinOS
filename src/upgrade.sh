#!/bin/bash
#==========================
# Set up the environment
#==========================
set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
export DEBIAN_FRONTEND=noninteractive
export LATEST_VERSION="1.1.4"
export CODE_NAME="noble"
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

function upgrade_110_to_111() {
    print_ok "Upgrading from 1.1.0 to 1.1.1..."
    dconf write /org/gnome/shell/keybindings/focus-active-notification "@as []"
    dconf write /org/gnome/shell/keybindings/toggle-quick-settings "['<Super>a']"
    judge "Upgrade from 1.1.0 to 1.1.1 completed"
}

function upgrade_111_to_112() {
    print_ok "Upgrading from 1.1.1 to 1.1.2..."
    dconf write /org/gnome/shell/extensions/arcmenu/show-update-notification-v64 false
    judge "Upgrade from 1.1.1 to 1.1.2 completed"
}

function upgrade_112_to_113() {
    print_ok "Upgrading from 1.1.2 to 1.1.3..."
    sudo apt update
    sudo apt upgrade -y
    judge "Upgrade from 1.1.2 to 1.1.3 completed"
}

function upgrade_113_to_114() {
    print_ok "Upgrading from 1.1.3 to 1.1.4..."
    sudo rm /usr/lib/firefox/mozilla.cfg || true
    sudo apt update
    sudo apt install -y \
      orca \
      spice-vdagent \
      bpfcc-tools \
      bpftrace \
      exfatprogs \
      gdb \
      gir1.2-wnck-3.0 \
      ieee-data \
      iw --no-install-recommends
    sudo apt -y install \
      linux-headers-$(uname -r) \
      linux-modules-$(uname -r) \
      linux-tools-$(uname -r) \
      linux-tools-common \
      --no-install-recommends
    judge "Upgrade from 1.1.3 to 1.1.4 completed"
}

function upgrade_114_to_115() {
    print_ok "Upgrading from 1.1.4 to 1.1.5..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y \
      gstreamer1.0-libav \
      --no-install-recommends
    judge "Upgrade from 1.1.4 to 1.1.5 completed"
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
          "1.1.0")
              upgrade_110_to_111
              upgrade_111_to_112
              upgrade_112_to_113
              upgrade_113_to_114
              ;;
          "1.1.1")
              upgrade_111_to_112
              upgrade_112_to_113
              upgrade_113_to_114
              ;;
          "1.1.2")
              upgrade_112_to_113
              upgrade_113_to_114
              ;;
          "1.1.3")
              upgrade_113_to_114
              ;;
          "1.1.4")
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