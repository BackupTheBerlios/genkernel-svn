# Output: binpackage { / -> "busybox" }
# Placement: TBD

busybox_compile::()
{
	local	BUSYBOX_SRCTAR="${SRCPKG_DIR}/busybox-${BUSYBOX_VER}.tar.bz2" BUSYBOX_DIR="busybox-${BUSYBOX_VER}" \
		BUSYBOX_CONFIG="${CONFIG_DIR}/busybox.config"
	[ -f "${BUSYBOX_SRCTAR}" ] || die "Could not find busybox source tarball: ${BUSYBOX_SRCTAR}!"

	[ -f "${BUSYBOX_CONFIG}" ] || BUSYBOX_CONFIG="${CONFIG_GENERIC_DIR}/busybox.config"
	[ -f "${BUSYBOX_CONFIG}" ] || die "Cound not find busybox config file: ${BUSYBOX_CONFIG}!"

	cd "${TEMP}"
	rm -rf ${BUSYBOX_DIR} > /dev/null
	unpack ${BUSYBOX_SRCTAR} || die 'Could not extract busybox source tarball!'
	[ -d "${BUSYBOX_DIR}" ] || die 'Busybox directory ${BUSYBOX_DIR} is invalid!'

	cd "${BUSYBOX_DIR}"
	cp "${BUSYBOX_CONFIG}" .config
	# TODO Add busybox config changing support
	
	config_set_builtin ".config" "CONFIG_FEATURE_INSTALLER"

	# turn on/off the cross compiler
	if [ -n "$(profile_get_key cross-compile)" ]
	then
		config_set_builtin ".config" "USING_CROSS_COMPILER"
		config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key cross-compile)"
    elif [ -n "$(profile_get_key utils-cross-compile)" ]
		config_set_builtin ".config" "USING_CROSS_COMPILER"
		config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	else
		config_unset ".config" "USING_CROSS_COMPILER"
		config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi

	print_info 1 'busybox: >> Configuring...'
	yes '' 2>/dev/null | compile_generic oldconfig

	
	print_info 1 'busybox: >> Compiling...'
	compile_generic all

	[ -f "busybox" ] || die 'Busybox executable does not exist!'
	strip "busybox" || die 'Could not strip busybox binary!'
	genkernel_generate_package "busybox-${BUSYBOX_VER}" "./busybox"

	cd "${TEMP}"
	rm -rf "${BUSYBOX_DIR}" > /dev/null
}
