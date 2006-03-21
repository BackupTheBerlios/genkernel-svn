uclibc_compile::()
{
	local	UCLIBC_SRCTAR="${SRCPKG_DIR}/uClibc-${UCLIBC_VER}.tar.bz2" UCLIBC_DIR="uClibc-${UCLIBC_VER}" 
	[ -f "${UCLIBC_SRCTAR}" ] || die "Could not find uclibc source tarball: ${UCLIBC_SRCTAR}!"

	cd "${TEMP}"
	rm -rf ${UCLIBC_DIR} > /dev/null
	unpack ${UCLIBC_SRCTAR} || die 'Could not extract uclibc source tarball!'
	[ -d "${UCLIBC_DIR}" ] || die 'uclibc directory ${UCLIBC_DIR} is invalid!'

	cd "${UCLIBC_DIR}"
   
	print_info 1 'uClibc: >> Configuring...'

	compile_generic defconfig
	
	# turn on/off the cross compiler
	if [ -n "$(profile_get_key cross-compile)" ]
	then
    	config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key cross-compile)"
    elif [ -n "$(profile_get_key utils-cross-compile)" ]
	then
    	config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	else
    	config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi

	UCLIBC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
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

	# just handle the ones that can be big or little
	UCLIBC_TARGET_ENDIAN=$(echo ${ARCH} | sed \
        -e 's/armeb/BIG/' \
        -e 's/arm/LITTLE/' \
        -e 's/mipsel/LITTLE/' \
        -e 's/mips/BIG/' \
	)

	if [ "${UCLIBC_TARGET_ENDIAN}" != "BIG" -o "${UCLIBC_TARGET_ENDIAN}" != "LITTLE" ]
	then
		UCLIBC_TARGET_ENDIAN=""
	fi

	if [ "${UCLIBC_TARGET_ENDIAN}" == "LITTLE" ]
	then
		UCLIBC_NOT_TARGET_ENDIAN="BIG"
	else
		UCLIBC_NOT_TARGET_ENDIAN="LITTLE"
	fi


	config_set .config TARGET_${UCLIBC_TARGET_ARCH} "y"
	config_set_string .config TARGET_ARCH "${UCLIBC_TARGET_ARCH}"
	config_set .config UCLIBC_HAS_RPC "y"
	config_set .config UCLIBC_HAS_FULL_RPC "y"
	config_set_string .config KERNEL_SOURCE "/usr"
	
	if [ -n "${UCLIBC_TARGET_ENDIAN}" ]
	then
		config_set .config ARCH_${UCLIBC_TARGET_ENDIAN}_ENDIAN "y"
		config_set .config ARCH_${UCLIBC_NOT_TARGET_ENDIAN}_ENDIAN "n"
	fi

	yes '' 2>/dev/null | compile_generic oldconfig

	
	print_info 1 'uClibc: >> Compiling...'
	compile_generic all
	
	[ -e "${TEMP}/uclibc-compile" ] && rm -r ${TEMP}/uclibc-compile
	compile_generic PREFIX="${TEMP}/uclibc-compile" install
	
	cd ${TEMP}/uclibc-compile
	genkernel_generate_package "uClibc-${UCLIBC_VER}" "."

	cd "${TEMP}"
	rm -rf "${UCLIBC_DIR}" > /dev/null
	rm -rf "${TEMP}/uclibc-compile" > /dev/null
}