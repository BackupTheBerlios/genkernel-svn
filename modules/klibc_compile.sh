require @kernel_src_tree:null:fail

klibc_compile::() {
	local KLIBC_DIR="klibc-${KLIBC_VER}" KLIBC_SRCTAR="${SRCPKG_DIR}/klibc-1.1.1.tar.gz"

	# PPC fixup for 2.6.14
	# Headers are moving around .. need to make them available
	if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
	then
	    if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
	    then
    		cd ${KERNEL_DIR}
		echo 'Applying hack to workaround 2.6.14+ PPC header breakages...'
    		compile_generic kernel 'include/asm'
	    fi
	fi

	cd "${TEMP}"
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
	[ ! -f "${KLIBC_SRCTAR}" ] && gen_die "Could not find klibc tarball: ${KLIBC_SRCTAR}"
	unpack "${KLIBC_SRCTAR}" || gen_die 'Could not extract klibc tarball'
	[ ! -d "${KLIBC_DIR}" ] && gen_die "klibc tarball ${KLIBC_SRCTAR} is invalid"
	cd "${KLIBC_DIR}"

	# Don't install to "//lib" fix
	sed -e 's:$(INSTALLROOT)/$(SHLIBDIR):$(INSTALLROOT)$(INSTALLDIR)/$(CROSS)lib:' -i klibc/Makefile
	if [ -f ${GK_SHARE}/pkg/byteswap.h ]
	then
		echo "Inserting byteswap.h into klibc"
		cp "${GK_SHARE}/pkg/byteswap.h" "include/"
	else
		echo "${GK_SHARE}/pkg/byteswap.h not found"
	fi

	print_info 1 'klibc: >> Compiling...'
	ln -snf "${KERNEL_DIR}" linux || gen_die "Could not link to ${KERNEL_DIR}"
	sed -i MCONFIG -e "s|prefix      =.*|prefix      = ${TEMP}/klibc-build-${KLIBC_VER}|g"

	# PPC fixup for 2.6.14
	if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
	then
		if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
        	then
			echo 'INCLUDE += -I$(KRNLSRC)/arch/$(ARCH)/include' >> MCONFIG
		fi
	fi

	if [ "${ARCH}" = 'um' ]
	then
		compile_generic utils "ARCH=um"
	elif [ "${ARCH}" = 'sparc64' ]
	then
		compile_generic utils "ARCH=sparc64 CROSS=sparc64-unknown-linux-gnu-"
	elif [ "${ARCH}" = 'x86' ]
	then
		compile_generic utils "ARCH=i386"
	else
		compile_generic utils
	fi

	compile_generic runtask 'install'

	# PPC fixup for 2.6.14
	if [ "${VER}" -eq '2' -a "${PAT}" -eq '6' -a "${SUB}" -ge '14' ]
	then
	    if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
	    then
		cd ${KERNEL_DIR}
		compile_generic kernel 'archclean'
	    fi
	fi

	cd ${TEMP}
	genkernel_generate_package "klibc-${KLIBC_VER}" klibc-build-${KLIBC_VER}
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
}
