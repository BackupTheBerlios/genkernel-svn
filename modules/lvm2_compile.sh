require device_mapper
lvm2_compile::() {
	local LVM2_DIR="LVM2.${LVM2_VER}" LVM2_SRCTAR="${SRCPKG_DIR}/LVM2.${LVM2_VER}.tgz"
	[ -f "${LVM2_SRCTAR}" ] || die "Could not find LVM2 source tarball: ${LVM2_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${TEMP}/${LVM2_DIR}"
	unpack "${LVM2_SRCTAR}" || die "Failed to unpack LVM2 sources!"
	[ -d "${LVM2_DIR}" ] || die "LVM2 directory ${LVM2_DIR} invalid!"

	cd "${LVM2_DIR}"
	print_info 1 'LVM2: >> Configuring...'

	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	./configure --enable-static_link --prefix=${TEMP}/LVM2 >> ${DEBUGFILE} 2>&1 ||
		die 'Configure of LVM2 failed!'

	mkdir -p "${TEMP}/LVM2"
	print_info 1 'LVM2: >> Compiling...'
	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	compile_generic utils # Compile
	compile_generic utils install

	cd "${TEMP}/LVM2"
	chmod u+w sbin/lvm.static # Fix crazy permissions to strip
	strip sbin/lvm.static || die 'Could not strip lvm.static!'
	genkernel_generate_package "lvm2-${LVM2_VER}" sbin/lvm.static || die 'Could not create LVM2 package!'

	cd "${TEMP}"
	rm -rf "${TEMP}/LVM2" "${TEMP}/${LVM2_DIR}"
}
