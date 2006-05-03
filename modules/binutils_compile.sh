require uclibc_stage1
binutils_compile::()
{
	local	BINUTILS_SRCTAR="${SRCPKG_DIR}/binutils-${BINUTILS_VER}.tar.bz2" BINUTILS_DIR="binutils-${BINUTILS_VER}" 
	[ -f "${BINUTILS_SRCTAR}" ] || die "Could not find binutils source tarball: ${BINUTILS_SRCTAR}!"

	cd "${TEMP}"
	rm -rf ${BINUTILS_DIR} > /dev/null
	unpack ${BINUTILS_SRCTAR} || die 'Could not extract binutils source tarball!'
	[ -d "${BINUTILS_DIR}" ] || die 'Binutils directory ${BINUTILS_DIR} is invalid!'

	cd "${BINUTILS_DIR}"
	
	gen_patch ${FIXES_PATCHES_DIR}/binutils/${BINUTILS_VER} .

	print_info 1 'binutils: >> Configuring...'
	
	BINUTILS_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
		-e 's/x86$/i386/' \
		-e 's/i.86$/i386/' \
		-e 's/sparc.*/sparc/' \
		-e 's/arm.*/arm/g' \
		-e 's/m68k.*/m68k/' \
		-e 's/ppc/powerpc/g' \
		-e 's/v850.*/v850/g' \
		-e 's/sh[234].*/sh/' \
		-e 's/mips.*/mips/' \
		-e 's/mipsel.*/mips/' \
		-e 's/cris.*/cris/' \
		-e 's/nios2.*/nios2/' \
	)

	CC="gcc" \
	configure_generic \
	--prefix=${TEMP}/binutils-staging \
        --build=${BINUTILS_TARGET_ARCH}-pc-linux-gnu \
        --host=${BINUTILS_TARGET_ARCH}-pc-linux-gnu \
        --target=${BINUTILS_TARGET_ARCH}-linux-uclibc \
        --disable-nls \
        --enable-multilib \
        --disable-werror


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
	#print_info 1 "${PRINT_PREFIX}>> Running uclibc menuconfig..."
	#compile_generic runtask ${KERNEL_ARGS} menuconfig
	#compile_generic defconfig

	#uclibc_config_set_string .config KERNEL_SOURCE "/usr"
	#yes '' 2>/dev/null | compile_generic oldconfig

	print_info 1 'binutils: >> Compiling...'
	compile_generic all
	
	
	mkdir ${TEMP}/binutils-staging
	
	compile_generic install
	
	cd ${TEMP}/binutils-staging
	genkernel_generate_package "binutils-${BINUTILS_VER}" "."

	cd "${TEMP}"
	rm -rf "${BINUTILS_DIR}" > /dev/null
	rm -rf ${TEMP}/binutils-staging > /dev/null
}
