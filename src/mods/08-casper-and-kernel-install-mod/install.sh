set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing capser (live-boot)..."
wait_network
apt install $INTERACTIVE \
    casper \
    discover \
    laptop-detect \
    os-prober \
    keyutils \
    --no-install-recommends
judge "Install live-boot"

TARGET_KERNEL_PACKAGE=$(apt search linux-generic-hwe-* | awk -F'/' '/linux-generic-hwe-/ {print $1}' | sort | head -n 1)
print_ok "Installing kernel package $TARGET_KERNEL_PACKAGE..."

# Architecture-specific packages
case "$TARGET_ARCH" in
    amd64)
        # Install thermald for Intel x86 thermal management
        apt install $INTERACTIVE \
            thermald \
            $TARGET_KERNEL_PACKAGE \
            --no-install-recommends
        ;;
    arm64)
        # Skip thermald on ARM64 (not applicable)
        apt install $INTERACTIVE \
            $TARGET_KERNEL_PACKAGE \
            --no-install-recommends
        ;;
esac
judge "Install kernel package"
