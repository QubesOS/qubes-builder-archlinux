#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mkdir -p $CACHEDIR/mnt_archlinux_dvd
mount $CACHEDIR/airootfs.img $CACHEDIR/mnt_archlinux_dvd

echo "Fix bug intruduced in arch-chroot causing arguments not to be passed"
sed "s/unshare --fork --pid//" -i $CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot

echo "Fix chroot cannot be umounted because of gpg-agent started by pacman"
sed "/chroot_teardown() {/a  pkill gpg-agent" -i $CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot
cat $CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot

echo "Creating chroot bootstrap environment"

mount --bind $INSTALLDIR $CACHEDIR/mnt_archlinux_dvd/mnt
cp /etc/resolv.conf $CACHEDIR/mnt_archlinux_dvd/etc

echo "-> Initializing pacman keychain"
# Note: pacman-key starts gpg-agent automatically, which locks /dev
$CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot $CACHEDIR/mnt_archlinux_dvd/ pacman-key --init
$CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot $CACHEDIR/mnt_archlinux_dvd/ pacman-key --populate

echo "-> Installing core pacman packages..."
$CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot $CACHEDIR/mnt_archlinux_dvd/ sh -c 'pacstrap /mnt base'

echo "--> Removing non required linux kernel (can be added manually through a package)"
$CACHEDIR/mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc linux

echo "-> Cleaning up bootstrap environment"

umount $CACHEDIR/mnt_archlinux_dvd/mnt

umount $CACHEDIR/mnt_archlinux_dvd

cp $SCRIPTSDIR/resolv.conf $INSTALLDIR/etc
