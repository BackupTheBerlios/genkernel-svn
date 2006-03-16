require uclibc binutils

gcc_compile::()
{
	local GCC_SRCTAR="${SRCPKG_DIR}/gcc-${GCC_VER}.tar.bz2" GCC_DIR="gcc-${GCC_VER}" 
	local GCC_BUILD_DIR="gcc-${GCC_VER}-build"
	#[ -f "${GCC_SRCTAR}" ] || die "Could not find binutils source tarball: ${GCC_SRCTAR}!"

	cd "${TEMP}"
	#rm -rf ${GCC_DIR} > /dev/null
	#unpack ${GCC_SRCTAR} || die 'Could not extract gcc source tarball!'
	#[ -d "${GCC_DIR}" ] || die 'gcc directory ${BINUTILS_DIR} is invalid!'

	mkdir -p "${GCC_BUILD_DIR}"
	cd "${GCC_BUILD_DIR}"



	#gen_patch ${FIXES_PATCHES_DIR}/gcc/${GCC_VER} .

    print_info 1 'gcc: >> Configuring...'

	GCC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
		-e 's/x86/i386/' \
		-e 's/i.86/i386/' \
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



	# binutils ... 
	LOCAL_PATH="${TEMP}/binutils-output/bin"

	# Cant use configure_generic here as we are running configure from a different directory
	# new funcion gcc_configure defined below
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	CC="gcc" \
	gcc_configure \
		--prefix=${TEMP}/gcc-output \
		--build=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--host=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--target=${GCC_TARGET_ARCH}-linux-uclibc \
		--enable-languages=c \
		--disable-shared \
		--with-sysroot=${TEMP}/uclibc-output/usr/${GCC_TARGET_ARCH}-linux-uclibc/ \
		--disable-__cxa_atexit \
		--enable-target-optspace \
		--with-gnu-ld \
		--disable-nls \
		--disable-threads \
		--enable-multilib


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

	
	print_info 1 'gcc: >> Compiling...'
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic all-gcc
#		make all-gcc
	
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic all-gcc
#		make install-gcc
	
	#[ -e "${TEMP}/uclibc-compile" ] && rm -r ${TEMP}/uclibc-compile
	#compile_generic PREFIX="${TEMP}/uclibc-compile" install
	
	#[ -f "busybox" ] || die 'Busybox executable does not exist!'
	#strip "busybox" || die 'Could not strip busybox binary!'
	
	#[ -e "${TEMP}/busybox-compile" ] && rm -r ${TEMP}/busybox-compile
	#mkdir ${TEMP}/busybox-compile
	
	#cp busybox ${BUSYBOX_CONFIG} ${TEMP}/busybox-compile
	cd ${TEMP}/gcc-output
	#ls -laR ${TEMP}/uclibc-compile|more
	genkernel_generate_package "gcc-${GCC_VER}" "."

	#cd "${TEMP}"
	#rm -rf "${UCLIBC_DIR}" > /dev/null
	#rm -rf "${TEMP}/uclibc-compile" > /dev/null
}

gcc_configure() {
	local RET
	if [ "$(profile_get_key debuglevel)" -gt "1" ]
	then
		# Output to stdout and debugfile
		${TEMP}/${GCC_DIR}/configure $(profile_get_key makeopts) "$@" 2>&1 | tee -a ${DEBUGFILE}
		RET=${PIPESTATUS[0]}
	else
		# Output to debugfile only
		${TEMP}/${GCC_DIR}/configure $(profile_get_key makeopts) "$@" >> ${DEBUGFILE} 2>&1
		RET=$?
	fi
	[ "${RET}" -eq '0' ] || die "Failed to configure ..."
}

