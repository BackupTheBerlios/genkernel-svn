require @pkg_binutils-${BINUTILS_VER}:null:binutils_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status
#package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

binutils::() {
	[ -e ${TEMP}/binutils-output ] && rm -r ${TEMP}/binutils-output
	mkdir -p ${TEMP}/binutils-output
	cd ${TEMP}/binutils-output

	genkernel_extract_package "binutils-${BINUTILS_VER}"
	mkdir -p ${TEMP}/uclibc-root
	cp -r ${TEMP}/binutils-output/* ${TEMP}/uclibc-root
}
