require @pkg_udev-${UDEV_VER}:null:udev_compile

udev::()
{
	genkernel_convert_tar_to_cpio "udev" "${UDEV_VER}"
}
