require @pkg_dmraid-${DMRAID_VER}:null:dmraid_compile

dmraid::()
{
	cd ${TEMP}

	# Set up links, generate CPIO
	rm -rf ${TEMP}/dmraid-cpiogen
	mkdir -p ${TEMP}/dmraid-cpiogen
	cd ${TEMP}/dmraid-cpiogen

	genkernel_extract_package "dmraid-${DMRAID_VER}"
	genkernel_generate_cpio_path "dmraid-${DMRAID_VER}" .
	initramfs_register_cpio "dmraid-${DMRAID_VER}"

	cd ${TEMP}
	rm -rf "${TEMP}/dmraid-cpiogen"
}
