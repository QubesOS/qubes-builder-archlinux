#!/usr/bin/env sh

echo "Signing all unsigned packages"

for filename in qubes-packages-mirror-repo/archlinux/pkgs/*.pkg.tar.xz ; do
	if ! [ -f "$filename.sig" ] ; then
		echo "Signing $filename"
		gpg2 --detach-sign "$filename"
	fi
done

sudo mount --bind qubes-packages-mirror-repo/archlinux chroot-archlinux/tmp/qubes-packages-mirror-repo

## release 3.1 Repository
echo "Generating 3.1 repository"

# Include 3.0 and 3.1 packages
# Repo Add need packages to be added in the right order as it only keeps the last entered package version
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.0.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.1.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.1.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.1.db.tar.gz "$pkg";done;'
# Include XEN 4.6.0
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes-vm-xen-4.6.0*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.1.db.tar.gz "$pkg";done;'

## release 3.2 Repository
echo "Generating 3.2 repository"

# Include 3.0 3.1 3.2 packages
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.0.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.2.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.1.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.2.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.2.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.2.db.tar.gz "$pkg";done;'

# Include XEN 4.6.*
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes-vm-xen-4.6.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r3.2.db.tar.gz "$pkg";done;'

## release 4.0 Repository
echo "Generating 4.0 repository"

# Include 3.0 3.1 3.2 and 4.0 packages
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.0.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r4.0.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.1.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r4.0.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*3.2.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r4.0.db.tar.gz "$pkg";done;'
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*4.0.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r4.0.db.tar.gz "$pkg";done;'

# Include XEN 4.8.*
sudo chroot chroot-archlinux su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes-vm-xen-4.8.*.pkg.tar.xz` ; do repo-add pkgs/qubes-r4.0.db.tar.gz "$pkg";done;'

echo "Signing all repositories"
for repo in "qubes-r3.1" "qubes-r3.2" "qubes-r4.0"; do
	echo "Signing repository $repo"
	# Replace link with the real thing because it cannot be uploaded easily to repository
	rm qubes-packages-mirror-repo/archlinux/pkgs/${repo}.db
	cp qubes-packages-mirror-repo/archlinux/pkgs/$repo.db.tar.gz qubes-packages-mirror-repo/archlinux/pkgs/$repo.db

	# Sign the package database
	gpg2 --detach-sign qubes-packages-mirror-repo/archlinux/pkgs/$repo.db
done

