require device_mapper
dmraid_compile::() {
	local DMRAID_DIR="dmraid/${DMRAID_VER}" DMRAID_SRCTAR="${SRCPKG_DIR}/dmraid-${DMRAID_VER}.tar.bz2"
	[ -f "${DMRAID_SRCTAR}" ] || die "Could not find dmraid source tarball: ${DMRAID_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${TEMP}/${DMRAID_DIR}"
	unpack "${DMRAID_SRCTAR}" || die "Failed to unpack dmraid sources!"
	[ -d "${DMRAID_DIR}" ] || die "dmraid directory ${DMRAID_DIR} invalid!"

	cd "${DMRAID_DIR}"
	print_info 1 'dmraid: >> Configuring...'

	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	./configure --enable-static_link --prefix=${TEMP}/dmraid >> ${DEBUGFILE} 2>&1 ||
		die 'Configure of dmraid failed!'

	mkdir -p "${TEMP}/dmraid"
	sed -i tools/Makefile -e "s|DMRAIDLIBS += -lselinux||g"

	print_info 1 'dmraid: >> Compiling...'
	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	compile_generic utils # Compile

	mkdir "${TEMP}/dmraid/sbin"
	install -m 0755 -s tools/dmraid "${TEMP}/dmraid/sbin/dmraid"

	cd "${TEMP}/dmraid"
	genkernel_generate_package "dmraid-${DMRAID_VER}" sbin/dmraid || die 'Could not create dmraid package!'\

	cd "${TEMP}"
	rm -rf "${TEMP}"/dmraid "${TEMP}/${DMRAID_DIR}"
}
