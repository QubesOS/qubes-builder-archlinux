#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 04_install_qubes.sh : Prepare chroot instance as a Qubes template
echo "--> Archlinux 04_install_qubes.sh"

set -e
if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# Support for legacy builder
if [ -n "$CACHEDIR" ]; then
    CACHE_DIR="$CACHEDIR"
fi

PACMAN_CACHE_DIR="${CACHE_DIR}/pacman_cache"

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    PACMAN_CUSTOM_REPO_DIR="${PWD}/pkgs-for-template/${DIST}"
else
    PACMAN_CUSTOM_REPO_DIR="${PACKAGES_DIR}"
fi

export PACMAN_CACHE_DIR PACMAN_CUSTOM_REPO_DIR "ALL_PROXY=$REPO_PROXY" NO_PROXY=127.0.0.1

echo "  --> Enabling x86 repos..."
su -c "echo '[multilib]' >> $INSTALL_DIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALL_DIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALL_DIR/etc/pacman.conf"
sudo sed -Ei 's,^#(Server *= *https://mirrors\.kernel\.org/),\1,' "$INSTALL_DIR/etc/pacman.d/mirrorlist"

echo "  --> Updating Qubes custom repository..."
# Repo Add need packages to be added in the right version number order as it only keeps the last entered package version
# shellcheck disable=SC2016


"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
    'mkdir -p /tmp/qubes-packages-mirror-repo/pkgs'

PKGS_DIR="$PACMAN_CUSTOM_REPO_DIR/pkgs"
# repo-add cannot create empty db anymore, do it manually
bsdtar -cf - -T /dev/null | gzip > "${PKGS_DIR}/qubes.db.tar.gz"
ln -s qubes.db.tar.gz "${PKGS_DIR}/qubes.db"
bsdtar -cf - -T /dev/null | gzip > "${PKGS_DIR}/qubes.files.tar.gz"
ln -s qubes.files.tar.gz "${PKGS_DIR}/qubes.files"

if [ "0${IS_LEGACY_BUILDER}" -eq 0 ]; then
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
        "cd /tmp/qubes-packages-mirror-repo && find . -name '*.pkg.tar.*' -print0 | xargs -0 -I {} mv {} pkgs/"
fi

"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
    'cd /tmp/qubes-packages-mirror-repo && for pkg in `ls -v pkgs/*.pkg.tar.zst`; do [ -f "$pkg" ] && repo-add pkgs/qubes.db.tar.gz "$pkg"; done;'

chown -R --reference="$PACMAN_CUSTOM_REPO_DIR" "$PACMAN_CUSTOM_REPO_DIR"

echo "  --> Registering Qubes custom repository..."
echo "### qubes-builder-begin" >> "$INSTALL_DIR/etc/pacman.conf"
echo "[qubes] " | sudo tee -a "$INSTALL_DIR/etc/pacman.conf"
echo "SigLevel = Never " | sudo tee -a "$INSTALL_DIR/etc/pacman.conf"
echo "Server = file:///tmp/qubes-packages-mirror-repo/pkgs " | sudo tee -a "$INSTALL_DIR/etc/pacman.conf"

run_pacman () {
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
        'proxy=$1; shift; trap break SIGINT SIGTERM; for i in 1 2 3 4 5; do ALL_PROXY=$proxy http_proxy=$proxy https_proxy=$proxy NO_PROXY=127.0.0.1 "$@" && exit; done; exit 1' sh "$REPO_PROXY" pacman "$@"
}

run_pacman_single () {
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" /bin/sh -c \
        'proxy=$1; shift; trap break SIGINT SIGTERM; ALL_PROXY=$proxy http_proxy=$proxy https_proxy=$proxy NO_PROXY=127.0.0.1 "$@"' sh "$REPO_PROXY" pacman "$@"
}

echo "  --> Synchronize resolv.conf..."
cp -- /etc/resolv.conf "${INSTALL_DIR}/etc/resolv.conf"

echo "  --> Updating pacman sources..."
run_pacman -Syu --noconfirm --noprogressbar

echo "  --> Checking available qubes packages (for debugging only)..."
run_pacman_single -Ss qubes || :

if [ -n "$USE_QUBES_REPO_VERSION" ]; then
    # we don't check specific value here, assume correct branch of
    # meta-packages component
    echo "  --> Installing repository qubes package..."
    repos_basename="${TEMPLATE_CONTENT_DIR}/../repos/archlinux-qubes-repo-${USE_QUBES_REPO_VERSION}"
    key_path="${TEMPLATE_CONTENT_DIR}/../keys/qubes-repo-archlinux-key-${USE_QUBES_REPO_VERSION}.asc"
    if [ "0$USE_QUBES_REPO_TESTING" -gt 0 ]; then
        echo "  --> Enabling current-testing repository..."
        cat "${repos_basename}-current-testing.conf" \
            >> "$INSTALL_DIR/etc/pacman.conf"
    fi
    cat "${repos_basename}-current.conf" \
        >> "$INSTALL_DIR/etc/pacman.conf"
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" pacman-key --add /proc/self/fd/0 < "${key_path}"
    key_fpr=$(gpg --with-colons --show-key "${key_path}"| grep ^fpr: | cut -d : -f 10)
    "${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" pacman-key --lsign "$key_fpr"
    echo "  --> Updating pacman sources..."
    run_pacman -Syu --noconfirm --noprogressbar
fi
echo "### qubes-builder-end" >> "$INSTALL_DIR/etc/pacman.conf"

echo "  --> Installing mandatory qubes packages..."
run_pacman -S --noconfirm --noprogressbar qubes-vm-dependencies

echo "  --> Installing recommended qubes apps"
run_pacman -S --noconfirm --noprogressbar qubes-vm-recommended

echo "  --> Installing repository qubes package..."
run_pacman -S --noconfirm --noprogressbar qubes-vm-repo

echo "  --> Updating template fstab file..."
cat >> "${INSTALL_DIR}/etc/fstab" <<EOF
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
tmpfs                   /dev/shm                                    tmpfs   defaults,size=1G            0 0
# This MUST be a ramfs, not a tmpfs!  The data here is incredibly sensitive
# (allows root access) and must not be leaked to disk.
tmpfs                   /etc/pacman.d/gnupg/private-keys-v1.d       ramfs   defaults,noexec,nosuid,nodev,mode=600    0 0

EOF

echo "  --> Configuring system to our preferences..."
# Name network devices using simple names (ethX)
ln -s /dev/null "${INSTALL_DIR}/etc/udev/rules.d/80-net-name-slot.rules"
# Enable some locales (incl. UTF-8)
sed 's/#en_US/en_US/g' -i "${INSTALL_DIR}/etc/locale.gen"
"${TEMPLATE_CONTENT_DIR}/arch-chroot-lite" "$INSTALL_DIR" locale-gen
echo 'LANG=en_US.UTF-8' > "${INSTALL_DIR}/etc/locale.conf"

# Creating a random file in /lib/modules to ensure that the directory in never deleted when packages are removed
mkdir -p "${INSTALL_DIR}/lib/modules"
touch "${INSTALL_DIR}/lib/modules/QUBES_NODELETE"

# Remove qubes local repository definition
sed '/### qubes-builder-begin/,/### qubes-builder-end/d' -i "${INSTALL_DIR}/etc/pacman.conf"
