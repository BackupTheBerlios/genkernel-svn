require @pkg_busybox-${BUSYBOX_VER}:null:busybox_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status
package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

busybox::()
{
	cd ${TEMP}
	genkernel_extract_package "busybox-${BUSYBOX_VER}"

	# Set up links, generate CPIO
	rm -rf ${TEMP}/busybox-cpiogen
	mkdir -p ${TEMP}/busybox-cpiogen/bin
	mv "${TEMP}/busybox" "${TEMP}/busybox-cpiogen/bin/busybox"

	for i in '[' ash sh mount uname echo cut; do
		ln ${TEMP}/busybox-cpiogen/bin/busybox ${TEMP}/busybox-cpiogen/bin/$i ||
			die "Busybox error: could not link ${i}!"
	done
	
	cd busybox-cpiogen 2>&1 >/dev/null
	genkernel_generate_cpio_files "busybox-${BUSYBOX_VER}" bin/*
	initramfs_register_cpio "busybox-${BUSYBOX_VER}"
}

busybox::check_package_status()
{
	logicTrue $(profile_get_key busybox-menuconfig) && __INTERNAL__PKG__CALLBACK__STATUS=true && return

	if [ -n "$(profile_get_key busybox-config)" ]
	then
		BUSYBOX_CONFIG="$(profile_get_key busybox-config)"
	elif [ -f "${CONFIG_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_DIR}/busybox.config"
	elif [ -f "${CONFIG_GENERIC_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_GENERIC_DIR}/busybox.config"
	elif [ "${DEFAULT_BUSYBOX_CONFIG}" != "" -a -f "${DEFAULT_BUSYBOX_CONFIG}" ]
	then
		BUSYBOX_CONFIG="${DEFAULT_BUSYBOX_CONFIG}"
	else
		die 'Error: No busybox .config specified, or file not found!'
	fi
	
	[ -e ${TEMP}/busybox-temp ] && rm -r ${TEMP}/busybox-temp
	mkdir -p ${TEMP}/busybox-temp
	cd ${TEMP}/busybox-temp
	genkernel_extract_package "busybox-${BUSYBOX_VER}"
	
	local MD5_CACHED_BUSY_CONFIG=$(md5sum busybox.config)
	local MD5_NEW_BUSY_CONFIG=$(md5sum ${BUSYBOX_CONFIG})
	
	[ -e ${TEMP}/busybox-temp ] && rm -r ${TEMP}/busybox-temp
	
	if [ "${MD5_CACHED_BUSY_CONFIG/ */}" != "${MD5_NEW_BUSY_CONFIG/ */}" ]
	then
		echo Debug: busybox recompile forced...
		__INTERNAL__PKG__CALLBACK__STATUS=true
	fi
}
