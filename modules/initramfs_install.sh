require initramfs_create

initramfs_install::() {
	local ARGS KNAME
	
	KNAME="$(profile_get_key kernel-name)"
	if logicTrue $(profile_get_key internal-initramfs)
	then
		print_info 1 "Skipping installation of the initramfs: --initramfs-internal enabled"
	else
		if logicTrue $(profile_get_key install)	
		then
			[ "$(profile_get_key debuglevel)" -gt "1" ] && ARGS="-v"
	
			if [ -n "$(profile_get_key initramfs-output)" ]
			then
				print_info 1 ">> Installing initramfs to $(profile_get_key install-initramfs-path)/initramfs-${KNAME}-${ARCH}-${KV_FULL}"
				cp ${ARGS} "${TEMP}/initramfs-output.cpio.gz" "$(profile_get_key install-initramfs-path)/initramfs-${KNAME}-${ARCH}-${KV_FULL}"
			else
				print_info 1 ">> Installing initramfs to /boot/initramfs-${KNAME}-${ARCH}-${KV_FULL}"
				cp ${ARGS} "${TEMP}/initramfs-output.cpio.gz" "/boot/initramfs-${KNAME}-${ARCH}-${KV_FULL}"
			fi
			
			messages_register '    root=/dev/ram0 real_root=/dev/$ROOT init=/linuxrc'
    		messages_register ''
    		messages_register '    Where $ROOT is the device node for your root partition as the'
    		messages_register '    one specified in /etc/fstab'
    		messages_register ''
    		messages_register "If you require Genkernel's hardware detection features; you MUST"
    		messages_register 'tell your bootloader to use the provided initramfs file. Otherwise;'
    		messages_register 'substitute the root argument for the real_root argument if you are'
    		messages_register 'not planning to use the initrd...'
		fi
	fi
}
