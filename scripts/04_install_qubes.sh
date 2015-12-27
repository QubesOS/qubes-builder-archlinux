#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 04_install_qubes.sh : Prepare chroot instance as a Qubes template
echo "--> Archlinux 04_install_qubes.sh"

PACMAN_CACHE_DIR="${CACHEDIR}/pacman_cache"
PACMAN_CUSTOM_REPO_DIR="${PWD}/pkgs-for-template/${DIST}"
export PACMAN_CACHE_DIR PACMAN_CUSTOM_REPO_DIR

set -e
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

echo "  --> Enabling x86 repos..."
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"

echo "  --> Updating Qubes custom repository..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "cd /tmp/qubes-packages-mirror-repo && repo-add pkgs/qubes.db.tar.gz pkgs/*.pkg.tar.xz"
chown -R --reference="$PACMAN_CUSTOM_REPO_DIR" "$PACMAN_CUSTOM_REPO_DIR"

echo "  --> Registering Qubes custom repository..."
cat >> "${INSTALLDIR}/etc/pacman.conf" <<EOF
[qubes] # QubesTMP
SigLevel = Optional TrustAll # QubesTMP
Server = file:///tmp/qubes-packages-mirror-repo/pkgs  # QubesTMP
EOF

echo "  --> Synchronize resolv.conf..."
cp /etc/resolv.conf "${INSTALLDIR}/etc/resolv.conf"

echo "  --> Updating packman sources..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman -Sy"

echo "  --> Installing qubes packages..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman -S --force --noconfirm qubes-vm-xen" # --force is needed because package uses unconventional /usr/sbin
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman -S --noconfirm qubes-vm-core"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "pacman -S --noconfirm qubes-vm-gui"

echo "  --> Updating template fstab file..."
cat >> "${INSTALLDIR}/etc/fstab" <<EOF
/dev/mapper/dmroot / ext4 defaults,noatime 1 1
/dev/xvdb /rw ext4 defaults,noatime 1 2
/dev/xvdc1 swap swap defaults 0 0
/rw/home /home none noauto,bind,defaults 0 0
EOF

echo "  --> Configuring system to our preferences..."
# Name network devices using simple names (ethX)
ln -s /dev/null "${INSTALLDIR}/etc/udev/rules.d/80-net-name-slot.rules"
# Initialize encoding to qubes standards
#ln -s /etc/sysconfig/i18n $INSTALLDIR/etc/locale.conf
# Enable some locales (incl. UTF-8)
sed 's/#en_US/en_US/g' -i "${INSTALLDIR}/etc/locale.gen"
sed 's/#en_DE/en_DE/g' -i "${INSTALLDIR}/etc/locale.gen"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" locale-gen

# Creating a random file in /lib/modules to ensure that the directory in never deleted when packages are removed
mkdir -p "${INSTALLDIR}/lib/modules"
touch "${INSTALLDIR}/lib/modules/QUBES_NODELETE"

# Ensure os-release is setup correctly or Fedora dracut will fail when displaying the OS
# also ensure that the path is relative, because root is in /newroot before dracut switch root
ln -s ../usr/lib/os-release "${INSTALLDIR}/etc/os-release"

# Disable qubes local repository
sed '/QubesTMP/d' -i "${INSTALLDIR}/etc/pacman.conf"

# Reregistering qubes repository to the remote version
echo "  --> Registering Qubes remote repository..."
cat >> "${INSTALLDIR}/etc/pacman.conf" <<EOF
[qubes]
Server = http://olivier.medoc.free.fr/archlinux/pkgs/
EOF
