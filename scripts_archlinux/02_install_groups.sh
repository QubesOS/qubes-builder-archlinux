#!/bin/sh
if [ -n "${TEMPLATE_FLAVOR}" ]; then
	PKGLISTFILE="$SCRIPTSDIR/packages_${TEMPLATE_FLAVOR}.list"
		if ! [ -r "${PKGLISTFILE}" ]; then
		echo "ERROR: ${PKGLISTFILE} does not exists!"
		exit 1
	fi
else
	PKGLISTFILE="$SCRIPTSDIR/packages.list"
fi

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mount $CACHEDIR/airootfs.img mnt_archlinux_dvd

echo "Fix bug intruduced in arch-chroot causing arguments not to be passed"
sed "s/unshare --fork --pid//" -i mnt_archlinux_dvd/usr/bin/arch-chroot

PKGGROUPS=`cat $PKGLISTFILE`

echo "-> Installing archlinux package groups..."
echo "-> Selected packages:"
echo "$PKGGROUPS"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --needed --noconfirm -S $PKGGROUPS

umount mnt_archlinux_dvd
