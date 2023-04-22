#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 01_install_core.sh : Create build chroot install of Archlinux using pacstrap
echo "--> Archlinux 01_install_core.sh"

set -e
if [ "${VERBOSE:-0}" -ge 2 ] || [ "${DEBUG:-0}" -eq 1 ]; then
    set -x
fi

# make sure pacman master private key is _not_ stored in the TemplateVM - see
# template_archlinux/arch-chroot-lite for details
unset SKIP_VOLATILE_SECRET_KEY_DIR

"${TEMPLATE_CONTENT_DIR}/../prepare-chroot-base" "$INSTALL_DIR" "$DIST"
