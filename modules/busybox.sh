require @pkg_busybox-${BUSYBOX_VER}:null:busybox_compile

busybox::()
{
	cd ${TEMP}
	genkernel_extract_package "busybox-${BUSYBOX_VER}"
}
