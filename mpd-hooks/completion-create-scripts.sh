#!/bin/bash

# This runs in host context.
# I just create a script which will be run later in chroot context.
# This then does various things including unpacking the wolfson
# tarballs we placed in the chroot earlier

TDIR=$1
mkdir -p $TDIR/tmp/hook-scripts
cat > $TDIR/tmp/hook-scripts/mpd << EOF
#!/bin/bash

# FIXME where is your audio stash?
cat >> /etc/fstab << EO2F
server:/audio /var/lib/mpd/music nfs ro,nolock,bg 0 0
server:/playlists /var/lib/mpd/playlists nfs ro,nolock,bg 0 0
EO2F

# I used a hacked kernel to handle the wolfson audio card
rm -rf /lib/modules /lib/firmware /boot/kernel.img
tar xCvf / /tmp/wolfson-kernel.tar
tar xCvf / /tmp/wolfson-scripts.tar

# Modified mpd.conf. Note this puts the state file in /var/run
# which means it won't persist over reboots, this may not be what
# you want (default is /var/lib/mpd/state).
cat > /etc/mpd.conf << EO2F
music_directory		"/var/lib/mpd/music"
playlist_directory		"/var/lib/mpd/playlists"
db_file			"/var/lib/mpd/tag_cache"
log_file			"syslog"
pid_file			"/var/run/mpd/pid"
state_file			"/var/run/mpd/state"
sticker_file                   "/var/lib/mpd/sticker.sql"
zeroconf_name			"Unnamed Music Player"

user				"mpd"

input {
        plugin "curl"
}

audio_output {
	type		"alsa"
	name		"My ALSA Device"
	device		"hw:0,0"	# optional
	mixer_device	"default"	# optional
	mixer_control	"HPOUT2 Digital"		# optional
	mixer_index	"0"		# optional
}

filesystem_charset		"UTF-8"
id3v1_encoding			"UTF-8"
EO2F

# This is some stuff I run on startup to clear any mpd state,
# configure the audio card, and set the volume to something sane.

# First we remove the "exit 0" at the end of the file
sed -i 's/^exit 0$//' /etc/rc.local

# Then add our stuff
cat >> /etc/rc.local << EO2F
mpc clear
mpc update
/usr/local/bin/Reset_paths.sh
/usr/local/bin/Playback_to_Lineout.sh

mpc volume 40
EO2F

# Customize the hostname appropriately
echo "test-mpd" > /etc/hostname

EOF

chmod 755 $TDIR/tmp/hook-scripts/mpd
