require @pkg_udev-${UDEV_VER}:null:udev_compile

udev::()
{
	cd ${TEMP}

	# Set up links, generate CPIO
	rm -rf ${TEMP}/udev-cpiogen
	mkdir -p ${TEMP}/udev-cpiogen
	cd ${TEMP}/udev-cpiogen

	genkernel_extract_package "udev-${UDEV_VER}"
	genkernel_generate_cpio_path "udev-${UDEV_VER}" .
	initramfs_register_cpio "udev-${UDEV_VER}"
}
