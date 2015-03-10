#!/bin/sh
ISO_VERSION=`date +%Y.%m`.01

mkdir -p $CACHEDIR

echo "Downloading Archlinux dvd..."
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso"
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso.sig"

export GNUPGHOME=$CACHEDIR/gpghome
mkdir -p $CACHEDIR/gpghome
echo "Verifying dvd..."
gpg --import "$SCRIPTSDIR/../keys/archlinux-master-keys.asc"

gpg --verify "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso.sig" "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" || exit

if [ "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" -nt $CACHEDIR/root-image.fs ]; then
	echo "Extracting squash filesystem from DVD..."
	mkdir -p $CACHEDIR/mnt_archlinux_dvd
	mount -o loop "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" $CACHEDIR/mnt_archlinux_dvd || echo "!!Error mounting iso to mnt_archlinux_dvd"
	cp $CACHEDIR/mnt_archlinux_dvd/arch/x86_64/airootfs.sfs $CACHEDIR/ || echo "!!Error copying root sfs file to \$CACHEDIR"
	umount $CACHEDIR/mnt_archlinux_dvd
	mount -o loop $CACHEDIR/airootfs.sfs $CACHEDIR/mnt_archlinux_dvd || echo "!!Error mounting root sfs"
	cp $CACHEDIR/mnt_archlinux_dvd/airootfs.img $CACHEDIR/ || echo "!!Error copying root fs file"
	umount $CACHEDIR/mnt_archlinux_dvd
	rm $CACHEDIR/airootfs.sfs
fi
