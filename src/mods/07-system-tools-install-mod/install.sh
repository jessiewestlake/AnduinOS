set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

waitNetwork
print_ok "Installing basic system tool packages..."
apt install $INTERACTIVE \
    apparmor \
    bash-completion \
    bind9-dnsutils \
    bolt \
    build-essential \
    busybox-static \
    command-not-found \
    coreutils \
    cpio \
    crash \
    cron \
    debconf-i18n \
    dmidecode \
    dosfstools \
    ed \
    ethtool \
    fdisk \
    file \
    firmware-sof-signed \
    ftp \
    gettext \
    grub-common \
    grub2-common \
    hdparm \
    hwdata \
    init \
    iproute2 \
    iptables \
    iputils-ping \
    iputils-tracepath \
    irqbalance \
    libpam-systemd \
    linux-firmware \
    locales \
    logrotate \
    lshw \
    lsof \
    man-db \
    manpages \
    manpages-dev \
    dns-root-data \
    usb-modeswitch \
    libmbim-utils \
    media-types \
    mtr-tiny \
    net-tools \
    network-manager \
    nftables \
    numactl \
    openssh-client \
    parted \
    pciutils \
    psmisc \
    resolvconf \
    rsync \
    strace \
    sudo \
    tcpdump \
    telnet \
    time \
    ufw \
    unzip \
    usbutils \
    uuid-runtime \
    wget \
    xz-utils \
    zstd \
    zip \
    powermgmt-base \
    modemmanager \
    dbus-user-session \
    dnsmasq-base \
    wpasupplicant \
    linux-sysctl-defaults \
    python3-rich\
    systemd-hwe-hwdb \
    efibootmgr \
    libpam-cap \
    ibverbs-providers \
    xauth \
    --no-install-recommends
judge "Install basic system tool packages"

print_ok "Fixing the package base-files to avoid system upgrading it..."
# Fix the package base-files to avoid system upgrading it. This is because Ubuntu may upgrade the package base-files and caused AnduinOS to be changed to Ubuntu.
# This will edit the file /var/lib/dpkg/status and change the status of the package base-files to hold.
apt-mark hold base-files
judge "Fix the package base-files to avoid system upgrading it"
