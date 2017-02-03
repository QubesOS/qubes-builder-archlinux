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
# Repo Add need packages to be added in the right version number order as it only keeps the last entered package version
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/*.pkg.tar.xz`; do repo-add pkgs/qubes.db.tar.gz "$pkg"; done;'
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
    "http_proxy='${REPO_PROXY}' pacman -Sy"

echo "  --> Checking available qubes packages (for debugging only)..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Ss qubes"

echo "  --> Installing qubes packages..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --noconfirm qubes-vm-xen"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --noconfirm qubes-vm-core"

echo "  --> Disabling remote qubes repository..."
test -f "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.conf" && mv  "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.conf" "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.disabled"
test -f "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.conf" && mv  "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.conf" "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.disabled"

echo "  --> Finishing installation of qubes packages..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --noconfirm qubes-vm-gui"

echo "  --> Updating template fstab file..."
cat >> "${INSTALLDIR}/etc/fstab" <<EOF
/dev/mapper/dmroot /                       ext4 defaults,noatime        1 1
/dev/xvdb		/rw			auto	noauto,defaults,discard	1 2
/rw/home        /home       none    noauto,bind,defaults 0 0
/dev/xvdc1      swap                    swap    defaults        0 0
/dev/xvdi	/mnt/removable	auto noauto,user,rw 0 0
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

# Disable qubes local repository
sed '/QubesTMP/d' -i "${INSTALLDIR}/etc/pacman.conf"

# Reregistering qubes repository to the remote version
#echo "  --> Registering Qubes remote repository..."
#test -f "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.disabled" && mv  "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.disabled" "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.1.conf"
#test -f "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.disabled" && mv  "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.disabled" "${INSTALLDIR}/etc/pacman.d/99-qubes-repository-3.2.conf"
