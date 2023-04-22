#! /bin/bash --

set -euo pipefail
if [ "${VERBOSE:-0}" -ge 2 ] || [ "${DEBUG:-0}" -eq 1 ]; then
    set -x
fi

# Support for legacy builder
# shellcheck disable=SC2153
if [ "0${IS_LEGACY_BUILDER:-0}" -eq 1 ]; then
    KEYS_DIR="${TEMPLATE_CONTENT_DIR}/../keys"
    export KEYS_DIR
fi

echo "--> Archlinux 00_prepare.sh"

if [[ -n "${REPO_PROXY+x}" ]]; then
    export "https_proxy=$REPO_PROXY" "http_proxy=$REPO_PROXY"
fi
ARCHLINUX_SRC_PREFIX="${ARCHLINUX_SRC_PREFIX:-https://mirrors.edge.kernel.org/archlinux}"
BOOTSTRAP_TARBALL=$(wget -O- "$ARCHLINUX_SRC_PREFIX"/iso/latest/sha256sums.txt | grep -o "archlinux-bootstrap-[0-9.]*-x86_64.tar.gz")
BOOTSTRAP_URL="${ARCHLINUX_SRC_PREFIX}/iso/latest/${BOOTSTRAP_TARBALL}"

mkdir -p "${CACHE_DIR}/pacman_cache"

echo "  --> Downloading Archlinux bootstrap tarball (v${ARCHLINUX_REL_VERSION-})..."

wget -N -P "$CACHE_DIR" "$BOOTSTRAP_URL"
wget -N -P "$CACHE_DIR" "${BOOTSTRAP_URL}.sig"

echo "  --> Preparing GnuPG to verify tarball..."
mkdir -p "${CACHE_DIR}/gpghome"
touch "${CACHE_DIR}/gpghome/pubring.gpg"
chmod -R go-rwx "${CACHE_DIR}/gpghome"
gpg --keyring "${CACHE_DIR}/gpghome/pubring.gpg" --import "${KEYS_DIR}/archlinux-master-keys.asc" || exit

echo "  --> Verifying tarball..."
gpg --keyring "${CACHE_DIR}/gpghome/pubring.gpg" --verify "${CACHE_DIR}/${BOOTSTRAP_TARBALL}.sig" "${CACHE_DIR}/${BOOTSTRAP_TARBALL}" || exit

if [ "${CACHE_DIR}/${BOOTSTRAP_TARBALL}" -nt "${CACHE_DIR}/bootstrap/.extracted" ]; then
    echo "  --> Extracting bootstrap tarball (nuking previous directory)..."
    rm -rf "${CACHE_DIR}/bootstrap/"
    mkdir -p "${CACHE_DIR}/bootstrap"
    # By default will extract to a "root.x86_64" directory; strip that off
    tar -xzC "${CACHE_DIR}/bootstrap" --strip-components=1 -f "${CACHE_DIR}/${BOOTSTRAP_TARBALL}"
    # Copy the distribution-provided version to be rewritten based on the
    # value of $ARCHLINUX_MIRROR each run (by the Makefile)
    cp -a "${CACHE_DIR}/bootstrap/etc/pacman.d/mirrorlist" "${CACHE_DIR}/bootstrap/etc/pacman.d/mirrorlist.dist"
    touch "${CACHE_DIR}/bootstrap/.extracted"
else
    echo "  --> NB: Bootstrap tarball not newer than bootstrap directory, will use existing!"
fi
