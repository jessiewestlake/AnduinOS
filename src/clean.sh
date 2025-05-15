#!/bin/bash

#==========================
# Set up the environment
#==========================
set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source $SCRIPT_DIR/shared.sh
source $SCRIPT_DIR/args.sh

function clean() {
    print_ok "Cleaning up..."
    sudo umount new_building_os/sys || sudo umount -lf new_building_os/sys || true
    sudo umount new_building_os/proc || sudo umount -lf new_building_os/proc || true
    sudo umount new_building_os/dev || sudo umount -lf new_building_os/dev || true
    sudo umount new_building_os/run || sudo umount -lf new_building_os/run || true
    sudo rm -rf new_building_os || true
    judge "Clean up rootfs"
    sudo rm -rf image || true
    judge "Clean up image"
    sudo rm -rf dist || true
    judge "Clean up dist"
    sudo rm -f $TARGET_NAME.iso || true
    judge "Clean up iso"
}

# =============   main  ================
cd $SCRIPT_DIR

clean
