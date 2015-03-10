#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mount $CACHEDIR/airootfs.img mnt_archlinux_dvd

echo "Fix bug intruduced in arch-chroot causing arguments not to be passed"
sed "s/unshare --fork --pid//" -i mnt_archlinux_dvd/usr/bin/arch-chroot

echo "--> Starting cleanup actions"
# Remove unused packages and their dependencies (make dependencies)
cleanuppkgs=`./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman -Qdt | grep -v kernel | cut -d " " -f 1`
echo "--> Packages that can be cleaned up: $cleanuppkgs"
if [ -n "$cleanuppkgs" ] ; then
	./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc $cleanuppkgs
fi

# Remove video plugins
echo "--> Removing video plugins"
VIDEOPKGS=`./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman -Qs -q xf86-video`
echo $VIDEOPKGS | ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc -

# Remove other font package
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc xorg-fonts-100dpi xorg-fonts-75dpi

# Clean pacman cache
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Scc

umount mnt_archlinux_dvd

#rm -f $INSTALLDIR/var/lib/rpm/__db.00* $INSTALLDIR/var/lib/rpm/.rpm.lock
#yum -c $PWD/yum.conf $YUM_OPTS clean packages --installroot=$INSTALLDIR

# Make sure that rpm database has right format (for rpm version in template, not host)
#echo "--> Rebuilding rpm database..."
#chroot `pwd`/mnt /bin/rpm --rebuilddb 2> /dev/null
