require @pkg_busybox-${BUSYBOX_VER}:null:busybox_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

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

	cd busybox-cpiogen
	genkernel_generate_cpio_files "busybox-${BUSYBOX_VER}" bin/*
	initramfs_register_cpio "busybox-${BUSYBOX_VER}"
}

busybox::check_package_status()
{
	echo Debug: busybox recompile forced...
	__INTERNAL__PKG__CALLBACK__STATUS=true
}
