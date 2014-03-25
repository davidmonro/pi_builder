#!/bin/bash

# This runs after all the other hooks (which will have prepared scripts etc
# in the chroot), copies in the qemu binary and runs the configscript in
# chroot context

echo "All unpacking and hooks run, starting configure stage under qemu"

# Paranoia
[ "$1" != "" ] || exit 1
[ "$1" != "/" ] || exit 1
[ "`realpath $1`" != "/" ] || exit 1

# Assuming you have arm...
cp /usr/bin/qemu-arm-static $1/usr/bin/
chroot $1 /configscript.sh
