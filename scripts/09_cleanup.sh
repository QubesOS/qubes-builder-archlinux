#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 09_cleanup.sh : Clean up the new chroot prior to image finalisation
echo "--> Archlinux 09_cleanup.sh"

set -e
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

# Remove unused packages and their dependencies (make dependencies)
cleanuppkgs="$("${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c 'pacman -Qdt | grep -v kernel | cut -d " " -f 1')"
if [ -n "$cleanuppkgs" ] ; then
    echo "  --> Packages that will be cleaned up: $cleanuppkgs"
    "${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c "pacman --noconfirm -Rsc $cleanuppkgs"
else
    echo "  --> NB: No packages to clean up"
fi

echo "  --> Removing video plugins..."
videopkgs="$("${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c 'pacman -Qs -q xf86-video')"
echo $videopkgs | "${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c 'pacman --noconfirm -Rsc -'

echo "  --> Removing other font packages..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman --noconfirm -Rsc xorg-fonts-100dpi xorg-fonts-75dpi"

# TODO: Be more deliberate here; is the umount necessary?
# Moreover, given where this script is called, should we be bothering
# arch-chroot-lite?
echo "  --> Cleaning up pacman state..."
umount "${INSTALLDIR}/var/cache/pacman" || true
unset PACMAN_CACHE_DIR
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman --noconfirm -Scc"

echo " --> Cleaning /etc/resolv.conf"
rm -f /etc/resolv.conf
