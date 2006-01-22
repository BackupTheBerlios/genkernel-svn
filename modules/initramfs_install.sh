require initramfs_create

# Set the destination path for the initramfs
if ! logicTrue $(profile_get_key internal-initramfs)
then
	if [ -z "$(profile_get_key install-initramfs-path)" ]
	then
    	profile_set_key install-initramfs-path "/boot"
	fi

	if [ -w $(dirname $(profile_get_key install-initramfs-path)) ]
	then
    	mkdir -p $(profile_get_key install-initramfs-path) || \
       	die "Could not make $(profile_get_key install-initramfs-path).  Set $(profile_get_key install-initramfs-path) to a writeable directory or run as root"
	else
    	print_info 1 ">> Initramfs install path: ${BOLD}$(profile_get_key install-initramfs-path) ${NORMAL}is not writeable attempting to use ${TEMP}/genkernel-output"
    	if [ ! -w ${TEMP} ]
    	then
        	die "Could not write to ${TEMP}/genkernel-output.  Set install-initramfs-path to a writeable directory or run as root"
    	else
        	mkdir -p ${TEMP}/genkernel-output || die "Could not make ${TEMP}/genkernel-output.  Set install-initramfs-path to a writeable directory or run as root"
        	profile_set_key install-initramfs-path "${TEMP}/genkernel-output"
    	fi
	fi
fi




initramfs_install::() {
	local ARGS KNAME
	
	if logicTrue $(profile_get_key internal-initramfs)
	then
		print_info 1 "Skipping installation of the initramfs: --initramfs-internal enabled"
	else
		[ "$(profile_get_key debuglevel)" -gt "1" ] && ARGS="-v"
	
		print_info 1 ">> Installing initramfs to $(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}"
		cp ${ARGS} "${TEMP}/initramfs-output.cpio.gz" "$(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}"
			
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
}
