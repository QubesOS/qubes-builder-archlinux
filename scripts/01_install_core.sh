#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 01_install_core.sh : Create build chroot install of Archlinux using pacstrap
echo "--> Archlinux 01_install_core.sh"

ARCHLINUX_PLUGIN_DIR="${ARCHLINUX_PLUGIN_DIR:-"${SCRIPTSDIR}/.."}"

set -e
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

"${ARCHLINUX_PLUGIN_DIR}/prepare-chroot-base" "$INSTALLDIR" "$DIST"
