#!/bin/sh
# This is a slightly modified version of the zcip.example script
# in the busybox distribution

# only for use as a "zcip" callback script
if [ "x$interface" = x ]
then
	exit 1
fi

# zcip should start on boot/resume and various media changes
case "$1" in
init)
	# for now, zcip requires the link to be already up,
	# and it drops links when they go down.  that isn't
	# the most robust model...
	exit 0
	;;
config)
	if [ "x$ip" = x ]
	then
		exit 1
	fi

	exec ip address add dev $interface \
		scope link local "$ip/16" broadcast +
	;;
deconfig)
	if [ x$ip = x ]
	then
		exit 1
	fi
	exec ip address del dev $interface local $ip
	;;
esac
exit 1
