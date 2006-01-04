require gmi busybox udev 

# Turn on evms if enabled on the command line
logicTrue $(config_get_key evms2) && require evms_host_compiled

# Turn on lvm2 if enabled on the command line
logicTrue $(config_get_key lvm2) && require lvm2

# Get kernel modules
# Register a new cpio of the kernel modules

# Turn on the overlays if they are enabled
# TODO


initramfs::() {

	# Add any external cpios if defined
	[ -n "$(config_get_key external-cpio)" ] && initramfs_register_external_cpio $(config_get_key external-cpio)
	
	print_info 1 'Merging:'
	for i in $(initramfs_register_cpio_read)
	do
		if [ ! -f "$i" ]
		then
			die "Invalid CPIO file in registry: ${i} -- file does not exist."
		fi
		if [ "$(dirname ${i})" == "${TEMP}" ]
		then
			print_info 1 "    $(basename ${i} .cpio.gz)"
		else
			print_info 1 "    ${i}"
		fi

		# Can't use < file; bash seems to barf on binary data...
		cat "$i" >> "${TEMP}/initramfs-output.cpio.gz"
	done
}
