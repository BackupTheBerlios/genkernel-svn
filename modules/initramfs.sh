require busybox udev gmi

initramfs::() {
	print_info 1 'Merging:'
	for i in $(initramfs_register_cpio_read)
	do
		if [ ! -f "${TEMP}/$i.cpio.gz" ]
		then
			die "Invalid CPIO file in registry: ${i} -- file does not exist."
		fi
		print_info 1 "    $i"

		# Can't use < file; bash seems to barf on binary data...
		cat "${TEMP}/$i.cpio.gz" >> "${TEMP}/initramfs-output.cpio.gz"
	done
}
