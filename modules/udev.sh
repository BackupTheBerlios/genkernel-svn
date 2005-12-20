require @pkg_udev-${UDEV_VER}:null:udev_compile

udev::()
{
	cd ${TEMP}
	genkernel_extract_package "udev-${UDEV_VER}"
}
