#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Functions library for GMI scripts, related to kernel configuration
# and modules
#


# Change kernel message verbosity to quiet
#
# (No parameters)
#
quiet_kmsg() {
	# if QUIET is set make the kernel less chatty
	[ -n "$QUIET" ] && echo '0' > /proc/sys/kernel/printk
}


# Change kernel message verbosity to verbose
#
# (No parameters)
#
verbose_kmsg() {
	# if QUIET is set make the kernel less chatty
	[ -n "$QUIET" ] && echo '6' > /proc/sys/kernel/printk
}


# Test whether we're running on UML or not
#
# (No parameters)
#
is_uml_sys() {
        grep -qs 'UML' /proc/cpuinfo
        return $?
}


# Load modules, except if there is a noMODNAME command-line option
#
# (No parameters)
#
load_modules() {
	if [ -d '/lib/modules' ]
	then
		good_msg 'Scanning module classes'
		cd /etc/modules
		for i in *
		do
			if has "no$i" $CMDLINE " "
			then
				dbg_msg "\tCMDLINE: no$i detected. Skipping load of $i class"
			else
				good_msg "\t$i class modules"
				for j in $(cat $i)
				do
					module_location=$(find /lib/modules/`uname -r` -name ${j}*)
					if [ -n "${module_location}" ]
					then
						if ! has $j $LOADED_MODULES " "
						then
							dbg_msg "\t\t$j module"
							#insmod "${module_location}"
							modprobe $j 2> /dev/null 1>&2
							LOADED_MODULES="${LOADED_MODULES} $j"
						fi
					fi
				done
			fi
		done
	fi

	[ -n "${SCANDELAY}" ] && sleep ${SCANDELAY} 
}


# Loads and start UnionFS, create appropriate directories as needed
#
# (No parameters)
#
setup_unionfs() {
	if [ "${USE_UNIONFS}" != "yes" ]
	then
		if [ -r /lib/modules/unionfs.ko ]
		then
			good_msg "Enabling UnionFS support"
			insmod /lib/modules/unionfs.ko
			dbg_msg "Mounting the base tmpfs for unionfs"
			mkdir ${UNIONS}/.base
			mount -t tmpfs tmpfs ${UNIONS}/.base
			mount -t unionfs -o dirs=${UNIONS}/.base=rw unionfs ${ROOTFS}
			export USE_UNIONFS="yes"
		else
			dbg_msg "The unionfs.ko module does not exist, unionfs disabled."
		fi
	fi
}
