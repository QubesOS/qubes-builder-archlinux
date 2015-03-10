#!/bin/sh
ISO_VERSION=`date +%Y.%m`.01

mkdir -p $CACHEDIR

echo "Downloading Archlinux dvd..."
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso"
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso.sig"

echo "Verifying dvd..."
gpg --import "$SCRIPTSDIR/archlinux-master-keys.asc"

gpg --verify "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso.sig" "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" || exit

if [ "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" -nt $CACHEDIR/root-image.fs ]; then
	echo "Extracting squash filesystem from DVD..."
	mkdir mnt_archlinux_dvd
	mount -o loop "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" mnt_archlinux_dvd || echo "!!Error mounting iso to mnt_archlinux_dvd"
	cp mnt_archlinux_dvd/arch/x86_64/airootfs.sfs $CACHEDIR/ || echo "!!Error copying root sfs file to \$CACHEDIR"
	umount mnt_archlinux_dvd
	mount -o loop $CACHEDIR/airootfs.sfs mnt_archlinux_dvd || echo "!!Error mounting root sfs"
	cp mnt_archlinux_dvd/airootfs.img $CACHEDIR/ || echo "!!Error copying root fs file"
	umount mnt_archlinux_dvd
	rm $CACHEDIR/airootfs.sfs
fi
