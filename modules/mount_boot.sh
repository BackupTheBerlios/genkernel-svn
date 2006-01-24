mount_boot::() {
	
	if ! egrep -q ' /boot ' /proc/mounts
	then
		if egrep -q '^[^#].+/boot.+' /etc/fstab
		then
			if [ "${UID}" == "0" ]
			then
				if ! mount /boot
				then
					die "${BOLD}WARNING${NORMAL}: Failed to mount /boot!"
				else
					print_info 1 'mount: /boot mounted successfully!'
				fi
			else
				print_warning 1 ">> Skipping mount of /boot.  Not running as root."
			fi

		else
			print_warning 1 "${BOLD}WARNING${NORMAL}: No mounted /boot partition detected!"
			print_warning 1 '         Run ``mount /boot`` to mount it!'
			echo
		fi
	elif isBootRO
	then
		if [ "${UID}" == "0" ]
		then
			if ! mount -o remount,rw /boot
			then
				die "${BOLD}WARNING${NORMAL}: Failed to remount /boot RW!"
			else
				print_info 1 "mount: /boot remounted read/write successfully!"
			fi
		else
			print_warning 1 ">> Skipping remount of /boot.  Not running as root."
		fi
	fi
}

isBootRO()
{
    for mo in `grep ' /boot ' /proc/mounts | cut -d ' ' -f 4 | sed -e 's/,/ /'`
    do
        if [ "x${mo}x" == "xrox" ]
        then
            return 0
        fi
    done
    return 1
}

