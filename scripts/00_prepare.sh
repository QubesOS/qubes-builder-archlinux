#! /bin/bash --

set -euo pipefail
[ "$VERBOSE" -ge 2 -o "$DEBUG" -gt 0 ] && set -x
echo "--> Archlinux 00_prepare.sh"

if [[ -n "${REPO_PROXY+x}" ]]; then
    export "https_proxy=$REPO_PROXY" "http_proxy=$REPO_PROXY"
fi
ARCHLINUX_PLUGIN_DIR="${ARCHLINUX_PLUGIN_DIR:-"${SCRIPTSDIR}/.."}"
ARCHLINUX_SRC_PREFIX="${ARCHLINUX_SRC_PREFIX:-https://mirrors.edge.kernel.org/archlinux}"
BOOTSTRAP_TARBALL=$(wget -qO- "$ARCHLINUX_SRC_PREFIX"/iso/latest/sha256sums.txt | grep -o "archlinux-bootstrap-[0-9.]*-x86_64.tar.gz")

BOOTSTRAP_URL="${ARCHLINUX_SRC_PREFIX}/iso/latest/${BOOTSTRAP_TARBALL}"


mkdir -p "${CACHEDIR}/pacman_cache"

echo "  --> Downloading Archlinux bootstrap tarball (v${ARCHLINUX_REL_VERSION-})..."

wget -N -P "$CACHEDIR" "$BOOTSTRAP_URL"
wget -N -P "$CACHEDIR" "${BOOTSTRAP_URL}.sig"

echo "  --> Preparing GnuPG to verify tarball..."
mkdir -p "${CACHEDIR}/gpghome"
touch "${CACHEDIR}/gpghome/pubring.gpg"
chmod -R go-rwx "${CACHEDIR}/gpghome"
gpg --keyring "${CACHEDIR}/gpghome/pubring.gpg" --import "${ARCHLINUX_PLUGIN_DIR}/keys/archlinux-master-keys.asc" || exit

echo "  --> Verifying tarball..."
gpg --keyring "${CACHEDIR}/gpghome/pubring.gpg" --verify "${CACHEDIR}/${BOOTSTRAP_TARBALL}.sig" "${CACHEDIR}/${BOOTSTRAP_TARBALL}" || exit

if [ "${CACHEDIR}/${BOOTSTRAP_TARBALL}" -nt "${CACHEDIR}/bootstrap/.extracted" ]; then
    echo "  --> Extracting bootstrap tarball (nuking previous directory)..."
    rm -rf "${CACHEDIR}/bootstrap/"
    mkdir -p "${CACHEDIR}/bootstrap"
    # By default will extract to a "root.x86_64" directory; strip that off
    tar -xzC "${CACHEDIR}/bootstrap" --strip-components=1 -f "${CACHEDIR}/${BOOTSTRAP_TARBALL}"
    # Copy the distribution-provided version to be rewritten based on the
    # value of $ARCHLINUX_MIRROR each run (by the Makefile)
    cp -a "${CACHEDIR}/bootstrap/etc/pacman.d/mirrorlist" "${CACHEDIR}/bootstrap/etc/pacman.d/mirrorlist.dist"
    touch "${CACHEDIR}/bootstrap/.extracted"
else
    echo "  --> NB: Bootstrap tarball not newer than bootstrap directory, will use existing!"
fi
