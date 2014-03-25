#!/bin/bash

# This script will be run in chroot context probably under qemu.

# FIXME Variables you can mess with
HOSTNAME=pi-base
MYUSERNAME=myuser


export LC_ALL=C LANGUAGE=C LANG=C
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

# This stops things trying to start daemons inside the chroot.
mkdir /tmp/fake
for i in initctl invoke-rc.d restart start stop start-stop-daemon service
do
	ln -s /bin/true /tmp/fake/$i
done
export PATH=/tmp/fake:$PATH
cat > /etc/resolv.conf <<EOF
# FIXME
# Contents of a valid resolv.conf file here
# This is only used during the build process
# and is removed in the cleanup phase at the end;
# it is assumed dhcp will configure this at runtime.
# For static IP, put the right bits here and fix the
# cleanup section at the end of the file
EOF

# FIXME replace with your syslog host
sed -i 's/^SYSLOG_OPTS=.*$/SYSLOG_OPTS="-R syslog.my.domain"/' /etc/default/busybox-syslogd

# Dash needs special handling
/var/lib/dpkg/info/dash.preinst install

# Preseed files can pre-configure packages.
if [ -d /tmp/preseeds/ ]; then
        for file in `ls -1 /tmp/preseeds/*`; do
        debconf-set-selections $file
        done
fi

# Actually configure the unpackage packages
dpkg --configure -a

ln -s /proc/mounts /etc/mtab

# FIXME you may need to change the root location and fstab contents if you format your SD card differently
echo 'dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p3 rootfstype=ext4 rootwait' > /boot/cmdline.txt

cat > /etc/fstab << EOF
/dev/mmcblk0p3	/	ext4	errors=remount-ro,noatime	0 1
/dev/mmcblk0p1	/boot	vfat	utf8				0 2
/dev/mmcblk0p2	none	swap	sw				0 0
tmpfs		/tmp	tmpfs	mode=1777,size=25%,noatime	0 0
EOF

# FIXME this should be the hash of the desired root password
echo 'root:$6$XXXXXXXX$YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY' | chpasswd -e

# FIXME with an appropriate hashed password for your non-root account
# You may also want to tailor the set of groups
groupadd ${MYUSERNAME}
useradd -c "My Name" -d /home/${MYUSERNAME} -m -g ${MYUSERNAME} -G adm,dialout,cdrom,floppy,audio,dip,video,plugdev -s /bin/bash -p '$6$ZZZZZZZZ$WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW' ${MYUSERNAME}

# FIXME put your SSH public key here if you want
mkdir /home/${MYUSERNAME}/.ssh
cat > /home/${MYUSERNAME}/.ssh/authorized_keys << EOF
ssh-dss stuff........
EOF

# FIXME grant yourself sudo access
echo "${MYUSERNAME} ALL=(ALL) ALL" >> /etc/sudoers


# This adds the key 7FA3303E: public key "Raspberry Pi Archive Signing Key"
# Needed for archive.raspberrypi.org/debian repo which doesn't seem to have
# a keyring package
apt-key add - << EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.12 (GNU/Linux)

mQENBE/d7o8BCACrwqQacGJfn3tnMzGui6mv2lLxYbsOuy/+U4rqMmGEuo3h9m92
30E2EtypsoWczkBretzLUCFv+VUOxaA6sV9+puTqYGhhQZFuKUWcG7orf7QbZRuu
TxsEUepW5lg7MExmAu1JJzqM0kMQX8fVyWVDkjchZ/is4q3BPOUCJbUJOsE+kK/6
8kW6nWdhwSAjfDh06bA5wvoXNjYoDdnSZyVdcYCPEJXEg5jfF/+nmiFKMZBraHwn
eQsepr7rBXxNcEvDlSOPal11fg90KXpy7Umre1UcAZYJdQeWcHu7X5uoJx/MG5J8
ic6CwYmDaShIFa92f8qmFcna05+lppk76fsnABEBAAG0IFJhc3BiZXJyeSBQaSBB
cmNoaXZlIFNpZ25pbmcgS2V5iQE4BBMBAgAiBQJP3e6PAhsDBgsJCAcDAgYVCAIJ
CgsEFgIDAQIeAQIXgAAKCRCCsSmSf6MwPk6vB/9pePB3IukU9WC9Bammh3mpQTvL
OifbkzHkmAYxzjfK6D2I8pT0xMxy949+ThzJ7uL60p6T/32ED9DR3LHIMXZvKtuc
mQnSiNDX03E2p7lIP/htoxW2hDP2n8cdlNdt0M9IjaWBppsbO7IrDppG2B1aRLni
uD7v8bHRL2mKTtIDLX42Enl8aLAkJYgNWpZyPkDyOqamjijarIWjGEPCkaURF7g4
d44HvYhpbLMOrz1m6N5Bzoa5+nq3lmifeiWKxioFXU+Hy5bhtAM6ljVb59hbD2ra
X4+3LXC9oox2flmQnyqwoyfZqVgSQa0B41qEQo8t1bz6Q1Ti7fbMLThmbRHiuQEN
BE/d7o8BCADNlVtBZU63fm79SjHh5AEKFs0C3kwa0mOhp9oas/haDggmhiXdzeD3
49JWz9ZTx+vlTq0s+I+nIR1a+q+GL+hxYt4HhxoA6vlDMegVfvZKzqTX9Nr2VqQa
S4Kz3W5ULv81tw3WowK6i0L7pqDmvDqgm73mMbbxfHD0SyTt8+fk7qX6Ag2pZ4a9
ZdJGxvASkh0McGpbYJhk1WYD+eh4fqH3IaeJi6xtNoRdc5YXuzILnp+KaJyPE5CR
qUY5JibOD3qR7zDjP0ueP93jLqmoKltCdN5+yYEExtSwz5lXniiYOJp8LWFCgv5h
m8aYXkcJS1xVV9Ltno23YvX5edw9QY4hABEBAAGJAR8EGAECAAkFAk/d7o8CGwwA
CgkQgrEpkn+jMD5Figf/dIC1qtDMTbu5IsI5uZPX63xydaExQNYf98cq5H2fWF6O
yVR7ERzA2w33hI0yZQrqO6pU9SRnHRxCFvGv6y+mXXXMRcmjZG7GiD6tQWeN/3wb
EbAn5cg6CJ/Lk/BI4iRRfBX07LbYULCohlGkwBOkRo10T+Ld4vCCnBftCh5x2OtZ
TOWRULxP36y2PLGVNF+q9pho98qx+RIxvpofQM/842ZycjPJvzgVQsW4LT91KYAE
4TVf6JjwUM6HZDoiNcX6d7zOhNfQihXTsniZZ6rky287htsWVDNkqOi5T3oTxWUo
m++/7s3K3L0zWopdhMVcgg6Nt9gcjzqN1c0gy55L/g==
=mNSj
-----END PGP PUBLIC KEY BLOCK-----
EOF

chown -R ${MYUSERNAME}: /home/${MYUSERNAME}/.ssh
chmod -R go= /home/${MYUSERNAME}/.ssh

# FIXME you'll want to change the wlan config
cat > /etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp

allow-hotplug wlan0
iface wlan0 inet dhcp
	wpa-ssid MY-SSID
	wpa-psk MY-PSK-PASSWORD
EOF
chmod 600 /etc/network/interfaces

echo $HOSTNAME > /etc/hostname

# This is a hack. I'm not sure why, but on the initial unpack/configure
# /boot ends up empty; this solves the issue.
apt-get -y update < /dev/null
apt-get -y install --reinstall raspberrypi-bootloader < /dev/null

# Run the other bits
run-parts -v /tmp/hook-scripts

# cleanup
apt-get clean
rm /etc/resolv.conf
rm -rf /tmp/*
exec rm /configscript.sh /usr/bin/qemu-arm-static
