#!/bin/bash
# Paranoia
[ "$1" != "" ] || exit 1
[ "$1" != "/" ] || exit 1
[ "`realpath $1`" != "/" ] || exit 1

# There's a bug in the base-files postinst where it breaks if anything
# other package has created directories under /var/run before the
# postinst runs. Presumably this never happens in a normal install.
# See https://bugs.launchpad.net/ubuntu/+source/base-files/+bug/874505
cat ~/pi-roots/minimal/base-files-6.5-postint.diff | patch $1/var/lib/dpkg/info/base-files.postinst
