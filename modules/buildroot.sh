require @pkg_buildroot-${BUILDROOT_VER}:null:buildroot_compile

buildroot::()
{
	cd ${TEMP}
	[ -e ${TEMP}/buildroot-temp ] && rm -r ${TEMP}/buildroot-temp
	mkdir -p ${TEMP}/buildroot-temp
	cd ${TEMP}/buildroot-temp
	genkernel_extract_package "buildroot-${BUILDROOT_VER}"

	mkdir -p /tmp/moo/buildroot/toolchain_build_i386/ccache-2.4/cache


	if logicTrue $(profile_get_key internal-uclibc)
	then
		print_info 1 ">> Setting utilities cross compiler to ${TEMP}/buildroot-temp/bin/i386-linux-uclibc-"
		profile_set_key utils-cross-compile "${TEMP}/buildroot-temp/bin/i386-linux-uclibc-"
	fi

}
