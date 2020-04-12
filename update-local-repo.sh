#!/bin/sh

# update-local-repo.sh: Add all available packages to the custom repository,
# initialising it if necessary
echo "-> Archlinux update-local-repo.sh"

PKGS_DIR="${BUILDER_REPO_DIR}/pkgs"

[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

mkdir -p "$PKGS_DIR"
if [ ! -f "${PKGS_DIR}/qubes.db" ]; then
    # pacman does not deal correctly with empty repositories
    echo "  -> Repo '${PKGS_DIR}' appears empty; initialising with pacman itself..."
    cp "${CHROOT_DIR}/var/cache/pacman/pkg"/pacman*.pkg.tar.* "${PKGS_DIR}/"
    cp "${CHROOT_DIR}/var/cache/pacman/pkg"/sudo*.pkg.tar.* "${PKGS_DIR}/"
    cp "${CACHEDIR}/pacman_cache/pkg"/pacman*.pkg.tar.* "${PKGS_DIR}/"
    cp "${CACHEDIR}/pacman_cache/pkg"/sudo*.pkg.tar.* "${PKGS_DIR}/"

fi

set -e

# Remove local qubes packages signatures because pacman will only trust these
# local packages if no signature is provided
env $CHROOT_ENV chroot "$CHROOT_DIR" /bin/su user -c \
    'cd /tmp/qubes-packages-mirror-repo/pkgs && if [ -n "$(ls *.sig)" ] ; then rm *.sig ; fi'

# Generate custom repository metadata based on packages that are available
# Repo Add need packages to be added in the right version number order as it only keeps the last entered package version
env $CHROOT_ENV chroot "$CHROOT_DIR" /bin/su user -c \
    'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/*.pkg.tar.*`; do repo-add pkgs/qubes.db.tar.gz "$pkg"; done;'

# Ensure pacman doesn't check for disk free space -- it doesn't work in chroots
env $CHROOT_ENV chroot "$CHROOT_DIR" /bin/sh -c \
    'sed "s/^ *CheckSpace/#CheckSpace/g" -i /etc/pacman.conf'

# Update archlinux keyring first so that Archlinux can be updated even after a long time
env $CHROOT_ENV chroot "$CHROOT_DIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Sy --noconfirm archlinux-keyring"

# Now update system
env $CHROOT_ENV chroot "$CHROOT_DIR" /bin/sh -c \
    "http_proxy='${REPO_PROXY}' pacman -Syu --noconfirm"
