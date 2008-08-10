# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/buildroot-${BUILDROOT_VER}.tar.bz2"

buildroot_compile::()
{
	local BUILDROOT_SRCTAR="${SRCPKG_DIR}/buildroot-${BUILDROOT_VER}.tar.bz2"
	local BUILDROOT_DIR="buildroot"
	
    [ -f "${BUILDROOT_SRCTAR}" ] || die "Could not find buildroot source tarball: ${BUILDROOT_SRCTAR}!"

	cd "${CACHE_DIR}"
	rm -rf ${BUILDROOT_DIR} >  /dev/null
	unpack ${BUILDROOT_SRCTAR} || die 'Could not extract buildroot source tarball!'
	[ -d "${BUILDROOT_DIR}" ] || die 'Buildroot directory ${BUILDROOT_DIR} is invalid!'
	mv "${BUILDROOT_DIR}" "${BUILDROOT_DIR}-$(profile_get_key utils-arch)"
    cd "${BUILDROOT_DIR}-$(profile_get_key utils-arch)"
	gen_patch ${FIXES_PATCHES_DIR}/buildroot/${BUILDROOT_VER} .
	print_info 1 'BUILDROOT: > Configuring...'
	compile_generic defconfig
	if [ "$(profile_get_key utils-arch)" == "x86_64" ]
	then
		print_info 1 'BUILDROOT: Compiling for x86_64, Nocona...'
		config_unset .config BR2_i386
		config_unset .config BR2_x86_i686
		config_set .config BR2_x86_64 y
		config_set .config BR2_x86_64_nocona y
		config_set .config BR2_ARCH x86_64
		config_set .config BR2_GCC_TARGET_TUNE nocona
		config_unset .config BR2_GCC_TARGET_ARCH

	fi
	config_set .config BR2_DL_DIR "${SRCPKG_DIR}"
	config_set .config BR2_LARGEFILE y
	config_set .config BR2_INET_IPV6 y
	config_set .config BR2_INET_RPC y
    config_unset .config BR2_PACKAGE_BUSYBOX
	config_unset .config BR2_TARGET_ROOTFS_EXT2
	config_unset .config BR2_TARGET_ROOTFS_CPIO

    print_info 1 'BUILDROOT Uclibc: > Configuring...'
    for def in UCLIBC_HAS_RPC UCLIBC_HAS_FULL_RPC MALLOC_GLIBC_COMPAT DO_C99_MATH UCLIBC_HAS_{RPC,CTYPE_CHECKED,WCHAR,HEXADECIMAL_FLOATS,GLIBC_CUS} PTHREADS_DEBUG_SUPPORT;do
        config_set toolchain/uClibc/uClibc-0.9.29.config ${def} "y"
    done

    print_info 1 'BUILDROOT: > Compiling...'
    compile_generic
    cp .config .config.gk
    genkernel_generate_package "buildroot-${BUILDROOT_VER}-$(profile_get_key utils-arch)-toolchain" "."
}
