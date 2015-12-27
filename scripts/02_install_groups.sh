#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 02_install_groups.sh : Install specified additional packages into chroot
echo "--> Archlinux 02_install_groups.sh"

set -e
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

if [ -n "$TEMPLATE_FLAVOR" ]; then
    PKGLISTFILE="${SCRIPTSDIR}/packages_${TEMPLATE_FLAVOR}.list"
    if ! [ -r "$PKGLISTFILE" ]; then
        echo "ERROR: PKGLISTFILE '${PKGLISTFILE}' does not exist!"
        exit 1
    fi
else
    PKGLISTFILE="${SCRIPTSDIR}/packages.list"
fi

# Strip comments, then convert newlines to single spaces
PKGGROUPS="$(sed '/^ *#/d; s/  *#.*//' "${PKGLISTFILE}" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

PACMAN_CACHE_DIR="${CACHEDIR}/pacman_cache"
export PACMAN_CACHE_DIR

echo "  --> Synchronize resolv.conf..."
cp /etc/resolv.conf "${INSTALLDIR}/etc/resolv.conf"

echo "  --> Installing archlinux package groups..."
echo "    --> Selected packages: ${PKGGROUPS}"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --needed --noconfirm ${PKGGROUPS}"
