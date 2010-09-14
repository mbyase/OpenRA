#!/bin/bash
ARGS=8
E_BADARGS=85

if [ $# -ne "$ARGS" ]
then
    echo "Usage: `basename $0` ftp-server ftp-path username password version src-dir temp-packaging-dir"
    exit $E_BADARGS
fi

PKGVERSION=`echo $5 | sed "s/-/\\./g"`

# Delete lines and insert updated ones for version
sed -i '2,2 d' ./DEBIAN/control
sed -i '11,11 i\Version: $PKGVERSION' ./DEBIAN/control
sed -i '1,1 d' ./DEBIAN/changelog
sed -i '1,1 i\openra ($PKGVERSION) unstable; urgency=low' ./DEBIAN/changelog

# Get the size needed for the Installed-Size line and change it
sed -i '5,5 d' ./DEBIAN/control
PACKAGE_SIZE= $( du --apparent-size -c ./usr | grep total | sed 's/[a-z]//g' | sed 's/\ //g')
sed -i '5,5 i\Installed-Size: $PACKAGE_SIZE' ./DEBIAN/control

# Copy our two needed folders to a clean package directory (yes, this is needed)
cp -R ./DEBIAN $7
cp -R $6/usr $7

# Build it in the package directory, but place the finished deb in our starting directory
BUILD_DIR=$( pwd )
pushd $7

# Calculate md5sums and clean up the /usr/ part of them
md5sum `find . -type f | grep -v '^[.]/DEBIAN/'` >DEBIAN/md5sums
sed -i 's/\.\/usr\//usr\//g' ./DEBIAN/md5sums

# Start building, the file should appear in directory the script was executed in
dpkg-deb -b . $BUILD_DIR/openra-$PKGVERSION.deb

# Get back to begin directory

popd

# Get package file and dump it on ftp

PACKAGEFILE=openra-$PKGVERSION.deb
size=`stat -c "%s" $PACKAGEFILE`

echo "$5,$size,$PACKAGEFILE" > /tmp/deblatest.txt

wput $PACKAGEFILE "ftp://$3:$4@$1/$2/"
cd /tmp
wput -u deblatest.txt "ftp://$3:$4@$1/$2/"

# remove temp-packaging-dir

rm -rf $7
