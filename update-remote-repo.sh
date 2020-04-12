#!/bin/bash

name=vm-archlinux
archlinux_directory=qubes-packages-mirror-repo/$name
package_directory=$archlinux_directory/pkgs
db=qubes.db

echo "Signing all unsigned packages"

for filename in $package_directory/*.pkg.tar.* ; do
	if ! [ -f "$filename.sig" ] ; then
		echo "Signing $filename"
		qubes-gpg-client-wrapper --detach-sign "$filename" > "$filename.sig"
	fi
done

sudo mount --bind $archlinux_directory chroot-$name/tmp/qubes-packages-mirror-repo

echo "Generating 4.0 repository"
sudo chroot chroot-$name su user -c 'cd /tmp/qubes-packages-mirror-repo; for pkg in `ls -v pkgs/qubes*.pkg.tar.*` ; do repo-add pkgs/'"$db"'.tar.gz "$pkg";done;'

# Replace link with the real thing because it cannot be uploaded easily to repository
rm $package_directory/$db
cp $package_directory/$db.tar.gz $package_directory/$db

# Sign the package database
qubes-gpg-client-wrapper --detach-sign $package_directory/$db > $package_directory/$db.sig

