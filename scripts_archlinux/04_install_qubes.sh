#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mkdir -p mnt_archlinux_dvd
mount $CACHEDIR/airootfs.img mnt_archlinux_dvd

echo "Fix bug intruduced in arch-chroot causing arguments not to be passed"
sed "s/unshare --fork --pid//" -i mnt_archlinux_dvd/usr/bin/arch-chroot

# Note: Enable x86 repos
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"

echo "--> Registering Qubes custom repository"

cat >> $INSTALLDIR/etc/pacman.conf <<EOF
[qubes] # QubesTMP
SigLevel = Optional TrustAll # QubesTMP
Server = file:///mnt/qubes-rpms-mirror-repo/pkgs # QubesTMP
EOF

export CUSTOMREPO=$PWD/yum_repo_qubes/archlinux
mkdir -p $INSTALLDIR/mnt/qubes-rpms-mirror-repo
mount --bind $CUSTOMREPO $INSTALLDIR/mnt/qubes-rpms-mirror-repo

./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "cd /mnt/qubes-rpms-mirror-repo/;repo-add pkgs/qubes.db.tar.gz pkgs/*.pkg.tar.xz"

chown -R --reference=$CUSTOMREPO $CUSTOMREPO

./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -Sy"

echo "--> Installing qubes-packages..."
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-xen"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-core"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-gui"

echo "--> Updating template fstab file..."
cat >> $INSTALLDIR/etc/fstab <<EOF
/dev/mapper/dmroot / ext4 defaults,noatime 1 1
/dev/xvdb /rw ext4 defaults,noatime 1 2
/dev/xvdc1 swap swap defaults 0 0
/rw/home /home none noauto,bind,defaults 0 0
EOF

echo "--> Configuring system to our preferences"
# Name network devices using simple names (ethX)
ln -s /dev/null $INSTALLDIR/etc/udev/rules.d/80-net-name-slot.rules
# Initialize encoding to qubes standards
ln -s /etc/sysconfig/i18n $INSTALLDIR/etc/locale.conf
# Enable some locales (incl. UTF-8
sed 's/#en_US/en_US/g' -i $INSTALLDIR/etc/locale.gen
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "locale-gen"

# Creating a random file in /lib/modules to ensure that the directory in never deleted when packages are removed
mkdir -p $INSTALLDIR/lib/modules
touch $INSTALLDIR/lib/modules/QUBES

# Ensure os-release is setup correctly or Fedora dracut will fail when displaying the OS
# also ensure that the path is relative, because root is in /newroot before dracut switch root
ln -s ../usr/lib/os-release $INSTALLDIR/etc/os-release

# Disable qubes local repository
sed '/QubesTMP/d' -i $INSTALLDIR/etc/pacman.conf

# Reregistering qubes repository to the remote version
echo "--> Registering Qubes remote repository"
cat >> $INSTALLDIR/etc/pacman.conf <<EOF
[qubes]
Server = http://olivier.medoc.free.fr/archlinux/pkgs/
EOF

echo "--> Cleaning up..."
umount $INSTALLDIR/mnt/qubes-rpms-mirror-repo
umount mnt_archlinux_dvd
