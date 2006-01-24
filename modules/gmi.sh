gmi::()
{
	cd ${TEMP}
	rm -rf "${TEMP}/initramfs-base-temp"
	mkdir -p ${TEMP}/initramfs-base-temp/{bin,etc,usr,proc,temp,sbin,sys}
	mkdir -p ${TEMP}/initramfs-base-temp/etc/modules
	mkdir -p ${TEMP}/initramfs-base-temp/usr/{s,}bin
	mkdir -p ${TEMP}/initramfs-base-temp/var/lock/dmraid

	# /lib64 -> /lib
	ln -s  ../lib ${TEMP}/initramfs-base-temp/lib64

	# Fill up fstab minimally so mount etc. doesn't complain
	cat <<- EOF > ${TEMP}/initramfs-base-temp/etc/fstab
		/dev/ram0     /           ext2    defaults
		proc          /proc       proc    defaults    0 0
	EOF
	
	# SGI LiveCDs need the following binary (no better place for it than here)
	# getdvhoff is a DEPEND of genkernel, so it *should* exist
	if [ "${MIPS_EMBEDDED_IMAGE}" != '' ]
	then
		[ -e /usr/lib/getdvhoff/getdvhoff ] \
			&& cp /usr/lib/getdvhoff/getdvhoff ${TEMP}/initramfs-base-temp/bin \
			|| die "sys-boot/getdvhoff not merged!"
	fi

	# This doesn't work as a user:
		# mknod -m 660 console c 5 1
		# mknod -m 660 null c 1 3
		# mknod -m 600 tty1 c 4 1
	
	# If not an internal-initramfs then copy the ready-made CPIO over instead...
	if ! logicTrue $(profile_get_key internal-initramfs)
	then
		cp "${GMI_DIR}/gmi-core-devices.cpio.gz" "${TEMP}" || die "Failed to copy over core device CPIO!"
		initramfs_register_cpio gmi-core-devices
	fi

	local LINUXRC=$(profile_get_key linuxrc)
	if [ -f "${LINUXRC}" ]
	then
		cp "${LINUXRC}" "${TEMP}/initramfs-base-temp/init"
		print_info 2 ">> Copying user specified linuxrc: ${LINUXRC} to init"
	else	
		if [ -f "${GMI_DIR}/${ARCH}/linuxrc" ]
		then
			cp "${GMI_DIR}/${ARCH}/linuxrc" "${TEMP}/initramfs-base-temp/init"
		else
			cp "${GMI_DIR}/generic/linuxrc" "${TEMP}/initramfs-base-temp/init"
		fi
	fi

	# Make a symlink to init in case we are bundled inside the kernel as one big cpio.
	cd ${TEMP}/initramfs-base-temp
	ln -s init linuxrc

	if [ -f "${GMI_DIR}/${ARCH}/initrd.scripts" ]
	then
		cp "${GMI_DIR}/${ARCH}/initrd.scripts" "${TEMP}/initramfs-base-temp/etc/initrd.scripts"
	else	
		cp "${GMI_DIR}/generic/initrd.scripts" "${TEMP}/initramfs-base-temp/etc/initrd.scripts"
	fi

	if [ -f "${GMI_DIR}/${ARCH}/initrd.defaults" ]
	then
		cp "${GMI_DIR}/${ARCH}/initrd.defaults" "${TEMP}/initramfs-base-temp/etc/initrd.defaults"
	else
		cp "${GMI_DIR}/generic/initrd.defaults" "${TEMP}/initramfs-base-temp/etc/initrd.defaults"
	fi
	
	echo -n 'HWOPTS="$HWOPTS ' >> "${TEMP}/initramfs-base-temp/etc/initrd.defaults"	
	for group_modules in ${!MODULES_*}; do
		group="$(echo $group_modules | cut -d_ -f2 | tr "[:upper:]" "[:lower:]")"
		echo -n "${group} " >> "${TEMP}/initramfs-base-temp/etc/initrd.defaults"
	done
	echo '"' >> "${TEMP}/initramfs-base-temp/etc/initrd.defaults"	

	#cp "${GMI_DIR}/generic/modprobe" "${TEMP}/initramfs-base-temp/sbin/modprobe"
	logicTrue "$(profile_get_key do-keymap-auto)" && echo 'MY_HWOPTS="${MY_HWOPTS} keymap"' >> ${TEMP}/initramfs-base-temp/etc/initrd.defaults
	logicTrue "$(profile_get_key bladecenter)" && echo 'MY_HWOPTS="${MY_HWOPTS} bladecenter"' >> ${TEMP}/initramfs-base-temp/etc/initrd.defaults

	mkdir -p "${TEMP}/initramfs-base-temp/lib/keymaps"
	/bin/tar -C "${TEMP}/initramfs-base-temp/lib/keymaps" -zxf "${GMI_DIR}/generic/keymaps.tar.gz"

	cd ${TEMP}/initramfs-base-temp/sbin && ln -s ../init init
	chmod +x "${TEMP}/initramfs-base-temp/init"
	chmod +x "${TEMP}/initramfs-base-temp/etc/initrd.scripts"
	chmod +x "${TEMP}/initramfs-base-temp/etc/initrd.defaults"
	#chmod +x "${TEMP}/initramfs-base-temp/sbin/modprobe"

	# Generate CPIO
	cd "${TEMP}/initramfs-base-temp/"
	genkernel_generate_cpio_path gmi-core .
	initramfs_register_cpio gmi-core

	cd "${TEMP}"
	rm -rf "${TEMP}/initramfs-base-temp"
}
