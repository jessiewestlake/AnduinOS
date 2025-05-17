set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Downloading software-properties-gtk..."
apt install -y \
  python3-dateutil \
  gir1.2-handy-1 \
  libgtk3-perl \
  --no-install-recommends
judge "Install python3-dateutil"

apt-get download "software-properties-gtk"
judge "Download software-properties-gtk"

DEB_FILE=$(ls *.deb)
print_ok "Found $DEB_FILE"

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

print_ok "Installing $MOD_DEB..."
dpkg -i "$MOD_DEB"
judge "Install $MOD_DEB"


FILE=/usr/lib/python3/dist-packages/softwareproperties/gtk/SoftwarePropertiesGtk.py

print_ok "Patching $FILE..."
sudo cp "$FILE" "${FILE}.bak"
sudo sed -i '/^from \.UbuntuProPage import UbuntuProPage$/d' "$FILE"
sudo sed -i '/^[[:space:]]*def init_ubuntu_pro/,/^[[:space:]]*$/d' "$FILE"
sudo sed -i '/^[[:space:]]*if is_current_distro_lts()/,/self.init_ubuntu_pro()/d' "$FILE"
judge "Edit $FILE"
