#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Functions library for GMI scripts, related to networking
#


# Starts networking.  Uses the 'ip=' kernel parameter, with the format described
# in /usr/src/linux/Documentation/nfsroot.txt.
# 
# (No parameters)
#
setup_networking() {
	if [ -n "${IP}" ]
	then
		#ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
		if [ "${IP}" = "dhcp" ]
		then
			if [ -e /sbin/udhcpc ]
			then
				good_msg "Setting up networking (${IP})"
				/sbin/udhcpc --now -s ${LIBGMI}/udhcp.sh > /dev/null
				assert "$?" "\t${IP} setup failed" || return 1
			fi

		elif [ "${IP}" = "bootp" -o "${IP}" = "rarp" ]
		then
			good_msg "Using kernel IP configuration (${IP})"
		else
			good_msg "Setting up networking (manual config)"
			CLIENT_IP=$(echo ${IP}|cut -d : -f 1)
			SERVER_IP=$(echo ${IP}|cut -d : -f 2)
			GW_IP=$(echo ${IP}|cut -d : -f 3)
			NETMASK=$(echo ${IP}|cut -d : -f 4)
			HOSTNAME=$(echo ${IP}|cut -d : -f 5)
			ETH_DEVICE=$(echo ${IP}|cut -d : -f 6)

			[ -n "${ETH_DEVICE}" ] && IFCONFIG_ETH_DEVICE="${ETH_DEVICE}" || IFCONFIG_ETH_DEVICE="eth0"
			# busybox ifconfig crashes if we dont bring up the device first	
			ifconfig ${IFCONFIG_ETH_DEVICE} up > /dev/null 2>&1
			[ -n "${NETMASK}" ] && IFCONFIG_ARGS="${IFCONFIG_ARGS} ${NETMASK}"
			
			# busybox ifconfig crashes if we dont bring up the device first	
			ifconfig ${IFCONFIG_ETH_DEVICE} ${CLIENT_IP} ${IFCONFIG_ARGS} up > /dev/null 2>&1

			if [ -n "${GW_IP}" ]
			then
				route add default gw ${GW_IP} > /dev/null 2>&1
			fi
		fi

		ifconfig lo up > /dev/null 2>&1

		if [ -e /sbin/portmap ]
		then
			portmap &
		fi

		if [ -n "${NAMESERVER}" ]
		then
			echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
		fi
	else
		return 0
	fi
}

