set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing live-boot..."
waitNetwork
apt install -y \
    casper \
    discover \
    laptop-detect \
    os-prober
judge "Install live-boot"

TARGET_KERNEL_PACKAGE=$(apt search linux-generic-hwe-* | awk -F'/' '/linux-generic-hwe-/ {print $1}' | sort | head -n 1)
print_ok "Installing kernel package $TARGET_KERNEL_PACKAGE..."
apt install -y --no-install-recommends $TARGET_KERNEL_PACKAGE
judge "Install kernel package"
sudo reboot