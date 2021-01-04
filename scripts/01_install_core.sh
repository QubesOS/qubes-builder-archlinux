#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 01_install_core.sh : Create build chroot install of Archlinux using pacstrap
echo "--> Archlinux 01_install_core.sh"

ARCHLINUX_PLUGIN_DIR="${ARCHLINUX_PLUGIN_DIR:-"${SCRIPTSDIR}/.."}"

set -e
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

# make sure pacman master private key is _not_ stored in the TemplateVM - see
# scripts/arch-chroot-lite for details
unset SKIP_VOLATILE_SECRET_KEY_DIR

"${ARCHLINUX_PLUGIN_DIR}/prepare-chroot-base" "$INSTALLDIR" "$DIST"
