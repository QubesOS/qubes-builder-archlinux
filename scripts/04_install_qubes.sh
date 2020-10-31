#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 04_install_qubes.sh : Prepare chroot instance as a Qubes template
echo "--> Archlinux 04_install_qubes.sh"

PACMAN_CACHE_DIR="${CACHEDIR}/pacman_cache"
PACMAN_CUSTOM_REPO_DIR="${PWD}/pkgs-for-template/${DIST}"
export PACMAN_CACHE_DIR PACMAN_CUSTOM_REPO_DIR

set -e
if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

echo "  --> Enabling x86 repos..."
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"

echo "  --> Updating Qubes custom repository..."
# Repo Add need packages to be added in the right version number order as it only keeps the last entered package version
# shellcheck disable=SC2016
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/*.pkg.tar.zst`; do repo-add pkgs/qubes.db.tar.gz "$pkg"; done;'
chown -R --reference="$PACMAN_CUSTOM_REPO_DIR" "$PACMAN_CUSTOM_REPO_DIR"

echo "  --> Registering Qubes custom repository..."
# shellcheck disable=SC2016
su -c 'echo "[qubes] " >> $INSTALLDIR/etc/pacman.conf'
# shellcheck disable=SC2016
su -c 'echo "SigLevel = Never " >> $INSTALLDIR/etc/pacman.conf'
# shellcheck disable=SC2016
su -c 'echo "Server = file:///tmp/qubes-packages-mirror-repo/pkgs " >> $INSTALLDIR/etc/pacman.conf' 

echo "  --> Synchronize resolv.conf..."
cp /etc/resolv.conf "${INSTALLDIR}/etc/resolv.conf"

echo "  --> Updating pacman sources..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Sy"

echo "  --> Checking available qubes packages (for debugging only)..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Ss qubes"

echo "  --> Installing mandatory qubes packages..."
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --noconfirm qubes-vm-dependencies"

echo "  --> Installing recommended qubes apps"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -S --noconfirm qubes-vm-recommended"

echo "  --> Copying binary repository keyring package"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" /bin/sh -c \
    "cp /tmp/qubes-packages-mirror-repo/pkgs/qubes-vm-keyring*.pkg.tar.* /etc/pacman.d/"

echo "  --> Updating template fstab file..."
cat >> "${INSTALLDIR}/etc/fstab" <<EOF
#
# /etc/fstab: static file system information
#

# Templates Directories
/dev/mapper/dmroot /                       ext4 defaults,discard,noatime        1 1
/dev/xvdb		/rw			auto	noauto,defaults,discard	1 2
/dev/xvdc1      swap                    swap    defaults        0 0

# Template Binds
/rw/home        /home       none    noauto,bind,defaults 0 0
/rw/usrlocal    /usr/local  none    noauto,bind,defaults 0 0

# Template Customizations
tmpfs                   /dev/shm                tmpfs   defaults,size=1G        0 0

EOF

echo "  --> Configuring system to our preferences..."
# Name network devices using simple names (ethX)
ln -s /dev/null "${INSTALLDIR}/etc/udev/rules.d/80-net-name-slot.rules"
# Enable some locales (incl. UTF-8)
sed 's/#en_US/en_US/g' -i "${INSTALLDIR}/etc/locale.gen"
"${SCRIPTSDIR}/arch-chroot-lite" "$INSTALLDIR" locale-gen
echo 'LANG=en_US.UTF-8' > "${INSTALLDIR}/etc/locale.conf"

# Creating a random file in /lib/modules to ensure that the directory in never deleted when packages are removed
mkdir -p "${INSTALLDIR}/lib/modules"
touch "${INSTALLDIR}/lib/modules/QUBES_NODELETE"

# Remove qubes local repository definition
sed '/\[qubes]/,+2 d' -i "${INSTALLDIR}/etc/pacman.conf"
