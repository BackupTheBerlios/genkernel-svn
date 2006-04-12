#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Script called by udhcpc to set up the networking given some variables
#

. /etc/initrd.defaults
. "${LIBGK}/libgmi.sh"

# Name the parameters
action="${1}"

RESOLV_CONF="/etc/resolv.conf"
[ -z "${1}" ] && gmi_bad_msg "Error: should be called from udhcpc" && exit 1
[ -n "${broadcast}" ] && BROADCAST="broadcast ${broadcast}"
[ -n "${subnet}" ] && NETMASK="netmask ${subnet}"

case "${1}" in
	renew|bound )
		/sbin/ifconfig ${interface} ${ip} ${BROADCAST} ${NETMASK}

		if [ -n "${router}" ]
		then
			gmi_dbg_msg "Deleting routers"
			while route del default gw 0.0.0.0 dev ${interface} 2> /dev/null; do
				:
			done

			for i in ${router} ; do
				route add default gw ${i} dev ${interface}
			done
		fi

		echo -n > ${RESOLV_CONF}
		[ -n "${domain}" ] && echo search ${domain} >> ${RESOLV_CONF}

		for entry in ${dns}
		do
			gmi_dbg_msg adding dns ${entry}
			echo nameserver ${entry} >> ${RESOLV_CONF}
		done
		;;
	deconfig )
		# remove the configuration of an interface
		/sbin/ifconfig ${interface} 0.0.0.0
		;;
esac
