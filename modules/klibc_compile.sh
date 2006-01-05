# Output: binpackage { /klibc-build-tree -> [[Build tree]] }
# Placement: Not relevant as not included in initramfs product.

# Used by the klibc module which defines KLCC to point to the klcc binary
# for usage by other modules.

require kernel_config
klibc_compile::() {
	local KLIBC_DIR="klibc-${KLIBC_VER}" KLIBC_SRCTAR="${SRCPKG_DIR}/klibc-1.1.1.tar.gz"

	#### This should be done in the kernel config code area

	## PPC fixup for 2.6.14
	## Headers are moving around .. need to make them available
	#if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
	#then
	#    if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
	#    then
	#		cd ${KERNEL_DIR}
	#	echo 'Applying hack to workaround 2.6.14+ PPC header breakages...'
	#		compile_generic kernel 'include/asm'
	#    fi
	#fi

	cd "${TEMP}"
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
	[ ! -f "${KLIBC_SRCTAR}" ] && die "Could not find klibc tarball: ${KLIBC_SRCTAR}"
	unpack "${KLIBC_SRCTAR}" || die 'Could not extract klibc tarball'
	[ ! -d "${KLIBC_DIR}" ] && die "klibc tarball ${KLIBC_SRCTAR} is invalid"
	cd "${KLIBC_DIR}"

	# Don't install to "//lib" fix
	sed -e 's:$(INSTALLROOT)/$(SHLIBDIR):$(INSTALLROOT)$(INSTALLDIR)/$(CROSS)lib:' -i klibc/Makefile
	
	if [ -f ${FIXES_FILES_DIR}/byteswap.h -a "${KLIBC_VER}" == '1.1.1' ]
	then
		print_info 1 '>> Inserting byteswap.h'
		cp "${FIXES_FILES_DIR}/byteswap.h" "include/"
	fi

	print_info 1 'klibc: >> Compiling...'
	
	ln -snf "$(config_get_key kernel-tree)" linux || die "Could not link to $(config_get_key kernel-tree)"
	sed -i MCONFIG -e "s|prefix      =.*|prefix      = ${TEMP}/klibc-build-${KLIBC_VER}|g" # Set the build directory

	if [ ! "$(config_get_key kbuild-output)" == "$(config_get_key kernel-tree)" ]
	then
		if [ "$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" \
		     -o "$(config_get_key arch-override)" == "xenU" ]
		then
			echo "KRNLOBJ = ${TEMP}/$(config_get_key arch-override)-i386" >> MCONFIG
		else
			echo "KRNLOBJ = $(config_get_key kbuild-output)" >> MCONFIG
		fi
	fi
	
	# PPC fixup for 2.6.14+
	if kernel_is ge 2 6 14
	then
		if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
      	then
			echo 'INCLUDE += -I$(KRNLSRC)/arch/$(ARCH)/include' >> MCONFIG
		fi
	fi

	if [ "${ARCH}" = 'um' -o "${ARCH}" = 'xen0' -o "${ARCH}" = 'xenU' ]
	then
		compile_generic "ARCH=i386"
	elif [ "${ARCH}" = 'sparc64' ]
	then
		compile_generic "ARCH=sparc64 CROSS=sparc64-unknown-linux-gnu-"
	elif [ "${ARCH}" = 'x86' ]
	then
		compile_generic "ARCH=i386"
	## FIXME: Cross-compile
	else
		compile_generic 
	fi

	compile_generic install

#### This should be done in the kernel config code area

#	# PPC fixup for 2.6.14
#	if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
#	then
#	    if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
#	    then
#		cd ${KERNEL_DIR}
#		compile_generic 'archclean'
#	    fi
#	fi

	cd ${TEMP}
	genkernel_generate_package "klibc-${KLIBC_VER}" klibc-build-${KLIBC_VER}
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
}
