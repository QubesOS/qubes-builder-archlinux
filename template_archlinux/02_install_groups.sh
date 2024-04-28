#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 02_install_groups.sh : Install specified additional packages into chroot
echo "--> Archlinux 02_install_groups.sh"

set -e
if [ "${VERBOSE:-0}" -ge 2 ] || [ "${DEBUG:-0}" -eq 1 ]; then
    set -x
fi

if [ -n "$TEMPLATE_FLAVOR" ]; then
    PKGLISTFILE="${TEMPLATE_CONTENT_DIR}/packages_${TEMPLATE_FLAVOR}.list"
    if ! [ -r "$PKGLISTFILE" ]; then
        echo "ERROR: PKGLISTFILE '${PKGLISTFILE}' does not exist!"
        exit 1
    fi
else
    PKGLISTFILE="${TEMPLATE_CONTENT_DIR}/packages.list"
fi

# Strip comments, then convert newlines to single spaces
PKGGROUPS="$(sed '/^ *#/d; s/  *#.*//' "${PKGLISTFILE}" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

PACMAN_CACHE_DIR="${CACHE_DIR}/pacman_cache"
export PACMAN_CACHE_DIR

echo "  --> Synchronize resolv.conf..."
cp /etc/resolv.conf "${INSTALL_DIR}/etc/resolv.conf"

echo "  --> Updating installed packages..."
"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Syu --noconfirm --noprogressbar"

echo "  --> Installing archlinux package groups..."
echo "    --> Selected packages: ${PKGGROUPS}"
"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --needed --noconfirm --noprogressbar ${PKGGROUPS}"
