require @pkg_gcc-${GCC_VER}:null:gcc_compile
require binutils

gcc::()
{
	cd ${TEMP}
	[ -e ${TEMP}/gcc-output ] && rm -r ${TEMP}/gcc-output
	mkdir -p ${TEMP}/gcc-output
	cd ${TEMP}/gcc-output
	genkernel_extract_package "gcc-${GCC_VER}"

	
	
	mkdir -p ${TEMP}/uclibc-root
	cp -r ${TEMP}/gcc-output/* ${TEMP}/uclibc-root

	profile_set_key utils-cross-compile "${TEMP}/uclibc-root/bin/i386-linux-uclibc-"

}
