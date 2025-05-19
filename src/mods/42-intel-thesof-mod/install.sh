set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

LINK="https://github.com/thesofproject/sof-bin/releases/download/v2025.01.1/sof-bin-2025.01.1.tar.gz"

(
    print_ok "Installing Intel SOF Mod"
    tempdir=$(mktemp -d)

    print_ok "Preparing installation directory $tempdir"
    cd "$tempdir" || exit 1

    print_ok "Downloading SOF binaries"
    wget "$LINK" -O sof-bin.tar.gz
    judge "Downloaded SOF binaries"

    print_ok "Extracting SOF binaries"
    tar -xzf sof-bin.tar.gz
    judge "Extracted SOF binaries"

    cd ./sof-bin-2025.01.1
    print_ok "Installing SOF binaries"
    ./install.sh
    judge "Installed SOF binaries"

    print_ok "Cleaning up"
    cd ..
    rm -rvf "$tempdir"
    judge "Cleaned up"
)