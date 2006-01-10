require gmi busybox udev kernel_modules_cpio

# Turn on evms if enabled on the command line
logicTrue $(config_get_key evms2) && require evms_host_compiled

# Turn on lvm2 if enabled on the command line
logicTrue $(config_get_key lvm2) && require lvm2

# Get kernel modules
# Register a new cpio of the kernel modules

initramfs::() {
	# Add any external cpios if defined
	[ -n "$(config_get_key external-cpio)" ] && initramfs_register_external_cpio $(config_get_key external-cpio)
	
	# Add the initramfs-overlay 	
	if [ -n "$(config_get_key initramfs-overlay)" ]
	then
		cd "$(config_get_key initramfs-overlay)" \
			|| die "Failed to generate the initramfs overlay from $(config_get_key initramfs-overlay)"
		genkernel_generate_cpio_path initramfs-overlay .
		initramfs_register_cpio initramfs-overlay
	fi

	if logicTrue $(config_get_key internal-initramfs)
	then
		# Build a single uncompressed cpio file
		mkdir "${TEMP}/initramfs-internal"
		
		for i in $(initramfs_register_cpio_read)
		do
			if [ ! -f "$i" ]
			then
				die "Invalid CPIO file in registry: ${i} -- file does not exist."
			fi
			genkernel_extract_cpio $i "${TEMP}/initramfs-internal"
		done
	else
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

			cp "${TEMP}/initramfs-output.cpio.gz" /boot/initramfs-output.cpio.gz
			ls -la ${TEMP}/initramfs-output.cpio.gz
		done
	fi
}
