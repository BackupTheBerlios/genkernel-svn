require kernel_config
logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/open-iscsi-${OPENISCSI_VER}.tar.gz"

open_iscsi_modules_compile::()
{
	local OPENISCSI_SRCTAR="${SRCPKG_DIR}/open-iscsi-${OPENISCSI_VER}.tar.gz" 
	local OPENISCSI_DIR="open-iscsi-${OPENISCSI_VER}"
	[ -f "${OPENISCSI_SRCTAR}" ] || die "Could not find open-iscsi source tarball: ${OPENISCSI_SRCTAR}!"

	cd "${CACHE_DIR}"
	rm -rf "${OPENISCSI_DIR}"
	unpack "${OPENISCSI_SRCTAR}" || die "Failed to unpack open-iscsi sources!"
	[ ! -d "${OPENISCSI_DIR}" ] && die "open-iscsi directory ${OPENISCSI_DIR} invalid"

	cd "${OPENISCSI_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/open-iscsi/${OPENISCSI_VER} .
	
   # turn on/off the cross compiler
	if [ -n "$(profile_get_key kernel-cross-compile)" ]
	then
		CC="$(profile_get_key kernel-cross-compile)-gcc"
	else
		CC="gcc"
	fi

	print_info 1 'open-iscsi-modules: >> Compiling...'
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		compile_generic KSRC=$(profile_get_key kernel-tree) KBUILD_OUTPUT=$(profile_get_key kbuild-output) KARCH=ARCH=$(profile_get_key kernel-arch) CC=${CC} -C kernel
	else
		compile_generic KSRC=$(profile_get_key kernel-tree) KARCH=ARCH=$(profile_get_key kernel-arch) -C kernel
	fi
	
	[ -e "${CACHE_DIR}/open-iscsi-modules" ] && rm -r ${CACHE_DIR}/open-iscsi-modules
    mkdir -p ${CACHE_DIR}/open-iscsi-modules
	
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		compile_generic KSRC=$(profile_get_key kernel-tree) KBUILD_OUTPUT=$(profile_get_key kbuild-output) KARCH=ARCH=$(profile_get_key kernel-arch) DESTDIR=${CACHE_DIR}/open-iscsi-modules -C kernel install_kernel
	else
		compile_generic KSRC=$(profile_get_key kernel-tree) KARCH=ARCH=$(profile_get_key kernel-arch) DESTDIR=${CACHE_DIR}/open-iscsi-modules -C kernel install_kernel
	fi
	
	cd ${CACHE_DIR}/open-iscsi-modules
    
	genkernel_generate_package "open-iscsi-${OPENISCSI_VER}-modules-${KV_FULL}" "."
	
	cd ${CACHE_DIR}

	rm -rf "${OPENISCSI_DIR}" > /dev/null
	rm -rf "${CACHE_DIR}/open-iscsi-modules" > /dev/null
}
