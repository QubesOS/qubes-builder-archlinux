#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
### 00_prepare.sh : Download and extract the archlinux bootstrap mini-distro
echo "--> Archlinux 00_prepare.sh"

ARCHLINUX_PLUGIN_DIR="${ARCHLINUX_PLUGIN_DIR:-"${SCRIPTSDIR}/.."}"

ARCHLINUX_SRC_PREFIX="${ARCHLINUX_SRC_PREFIX:-http://mirrors.kernel.org/archlinux}"
BOOTSTRAP_TARBALL=$(wget -qO- $ARCHLINUX_SRC_PREFIX/iso/latest/sha1sums.txt | grep bootstrap | awk '{print $2}')

BOOTSTRAP_URL="${ARCHLINUX_SRC_PREFIX}/iso/latest/${BOOTSTRAP_TARBALL}"
GPG_ENV="GNUPGHOME=${CACHEDIR}/gpghome"

[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x

mkdir -p "${CACHEDIR}/pacman_cache"

echo "  --> Downloading Archlinux bootstrap tarball (v${ARCHLINUX_REL_VERSION})..."

http_proxy="$REPO_PROXY" wget -N -P "$CACHEDIR" "$BOOTSTRAP_URL"
http_proxy="$REPO_PROXY" wget -N -P "$CACHEDIR" "${BOOTSTRAP_URL}.sig"

echo "  --> Preparing GnuPG to verify tarball..."
mkdir -p "${CACHEDIR}/gpghome"
chmod -R go-rwx "${CACHEDIR}/gpghome"
env $GPG_ENV gpg --import "${ARCHLINUX_PLUGIN_DIR}/keys/archlinux-master-keys.asc" || exit

echo "  --> Verifying tarball..."
env $GPG_ENV gpg --verify "${CACHEDIR}/${BOOTSTRAP_TARBALL}.sig" "${CACHEDIR}/${BOOTSTRAP_TARBALL}" || exit

if [ "${CACHEDIR}/${BOOTSTRAP_TARBALL}" -nt "${CACHEDIR}/bootstrap/.extracted" ]; then
    echo "  --> Extracting bootstrap tarball (nuking previous directory)..."
    rm -rf "${CACHEDIR}/bootstrap/"
    mkdir -p "${CACHEDIR}/bootstrap"
    # By default will extract to a "root.x86_64" directory; strip that off
    tar xzC "${CACHEDIR}/bootstrap" --strip-components=1 -f "${CACHEDIR}/${BOOTSTRAP_TARBALL}"
    # Copy the distribution-provided version to be rewritten based on the
    # value of $PACMAN_MIRROR each run (by the Makefile)
    cp -a "${CACHEDIR}/bootstrap/etc/pacman.d/mirrorlist" "${CACHEDIR}/bootstrap/etc/pacman.d/mirrorlist.dist"
    touch "${CACHEDIR}/bootstrap/.extracted"
else
    echo "  --> NB: Bootstrap tarball not newer than bootstrap directory, will use existing!"
fi
