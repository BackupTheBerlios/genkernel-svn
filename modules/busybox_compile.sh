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
	sed -i -e 's/#\? \?CONFIG_FEATURE_INSTALLER[ =].*/CONFIG_FEATURE_INSTALLER=y/g' .config

	print_info 1 'busybox: >> Configuring...'
	# TODO Add busybox config changing support
	yes '' 2>/dev/null | compile_generic oldconfig
	print_info 1 'busybox: >> Compiling...'
	compile_generic all

	[ -f "busybox" ] || die 'Busybox executable does not exist!'
	strip "busybox" || die 'Could not strip busybox binary!'
	genkernel_generate_package "busybox-${BUSYBOX_VER}" "./busybox"

	cd "${TEMP}"
	rm -rf "${BUSYBOX_DIR}" > /dev/null
}
