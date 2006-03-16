buildroot_compile::()
{
	local BUILDROOT_SRCTAR="${SRCPKG_DIR}/buildroot-${BUILDROOT_VER}.tar.bz2" BUILDROOT_DIR="buildroot" 
	[ -f "${BUILDROOT_SRCTAR}" ] || die "Could not find uclibc source tarball: ${BUILDROOT_SRCTAR}!"

	cd "${TEMP}"
	rm -rf ${BUILDROOT_DIR} > /dev/null
	unpack ${BUILDROOT_SRCTAR} || die 'Could not extract buildroot source tarball!'
	[ -d "${BUILDROOT_DIR}" ] || die 'buildroot directory ${BUILDROOT_DIR} is invalid!'

	cd "${BUILDROOT_DIR}"
   
	# turn on/off the cross compiler
	#if [ -n "$(profile_get_key cross-compile)" ]
	#then
	#	busybox_config_set ".config" "USING_CROSS_COMPILER" "y"
	#	busybox_config_set ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key cross-compile)"
    #elif [ -n "$(profile_get_key utils-cross-compile)" ]
	#then
	#	busybox_config_set ".config" "USING_CROSS_COMPILER" "y"
	#	busybox_config_set ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	#else
	#	busybox_config_unset ".config" "USING_CROSS_COMPILER"
	#	busybox_config_unset ".config" "CROSS_COMPILER_PREFIX"
	#fi

	#Setup the architecture
	#Setup minimum needed to build the root
	#Copy the source files needed into place
	
	print_info 1 "${PRINT_PREFIX}>> Running buildroot menuconfig..."
	compile_generic runtask menuconfig

	config_set_string .config BR2_STAGING_DIR "${TEMP}/buildroot-output"
	yes '' 2>/dev/null | compile_generic oldconfig

	
	[ -e "${TEMP}/buildroot-output" ] && rm -r ${TEMP}/buildroot-output
	print_info 1 'buildroot: >> Compiling...'
	compile_generic runtask
	ls -laR ${TEMP}/buildroot-output|more	
	cd ${TEMP}/buildroot-output
	genkernel_generate_package "buildroot-${BUILDROOT_VER}" "."

	cd "${TEMP}"
	rm -rf "${BUILDROOT_DIR}" > /dev/null
	rm -rf "${TEMP}/buildroot-output" > /dev/null
}

