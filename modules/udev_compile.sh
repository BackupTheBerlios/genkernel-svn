require klibc

udev_compile::() {
	local UDEV_DIR="udev-${UDEV_VER}" UDEV_SRCTAR="${SRCPKG_DIR}/udev-${UDEV_VER}.tar.bz2"

	cd "${TEMP}"
	rm -rf "${UDEV_DIR}" udev
	[ ! -f "${UDEV_SRCTAR}" ] && gen_die "Could not find udev tarball: ${UDEV_SRCTAR}"
	/bin/tar -jxpf "${UDEV_SRCTAR}" || gen_die 'Could not extract udev tarball'
	[ ! -d "${UDEV_DIR}" ] && gen_die "udev tarball ${UDEV_SRCTAR} is invalid"

	cd "${UDEV_DIR}"
	local extras="extras/scsi_id extras/volume_id extras/ata_id extras/run_directory extras/usb_id extras/floppy extras/cdrom_id extras/firmware"
    	# No selinux support yet .. someday maybe
	# use selinux && myconf="${myconf} USE_SELINUX=true"

	print_info 1 'udev: >> Compiling...'
	# PPC fixup for 2.6.14
	if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
        then
		if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
        	then
			# Headers are moving around .. need to make them available
			echo "CFLAGS += -I${KERNEL_DIR}/arch/${ARCH}/include" >> Makefile
		fi
	fi

	if [ "${ARCH}" = 'um' ]
	then
		compile_generic utils "EXTRAS=\"${extras}\" ARCH=um USE_KLIBC=true KLCC=${KLCC} USE_LOG=false DEBUG=false udevdir=/dev all"
	elif [ "${ARCH}" = 'sparc64' ]
	then
		compile_generic utils "EXTRAS=\"${extras}\" ARCH=sparc64 CROSS=sparc64-unknown-linux-gnu- USE_KLIBC=true KLCC=${KLCC} USE_LOG=false DEBUG=false udevdir=/dev all"
	else
		compile_generic utils "EXTRAS=\"${extras}\" USE_KLIBC=true KLCC=${KLCC} USE_LOG=false DEBUG=false udevdir=/dev all"
	fi

	print_info 1 '      >> Installing...'
	install -d "${TEMP}/udev/etc/udev" "${TEMP}/udev/sbin" "${TEMP}/udev/etc/udev/scripts" "${TEMP}/udev/etc/udev/rules.d" "${TEMP}/udev/etc/udev/permissions.d" "${TEMP}/udev/etc/udev/extras" "${TEMP}/udev/etc" "${TEMP}/udev/sbin" "${TEMP}/udev/usr/" "${TEMP}/udev/usr/bin" "${TEMP}/udev/usr/sbin"||
		gen_die 'Could not create directory hierarchy'

	install -c etc/udev/gentoo/udev.rules "${TEMP}/udev/etc/udev/rules.d/50-udev.rules" ||
	    gen_die 'Could not copy gentoo udev.rules to 50-udev.rules'

	compile_generic runtask "EXTRAS=\"${extras}\" DESTDIR=${TEMP}/udev install-config"
	compile_generic runtask "EXTRAS=\"${extras}\" DESTDIR=${TEMP}/udev install-bin"
	install -c extras/ide-devfs.sh "${TEMP}/udev/etc/udev/scripts" 
	install -c extras/scsi-devfs.sh "${TEMP}/udev/etc/udev/scripts" 
	install -c extras/raid-devfs.sh "${TEMP}/udev/etc/udev/scripts" 

	cd "${TEMP}/udev"
	genkernel_generate_package "udev-${UDEV_VER}" '.'

	cd "${TEMP}"
	rm -rf "${UDEV_DIR}" udev
}
