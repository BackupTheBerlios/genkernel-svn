device_mapper_compile::()
{
	local DEVICE_MAPPER_SRCTAR="${SRCPKG_DIR}/device-mapper.${DEVICE_MAPPER_VER}.tgz" DEVICE_MAPPER_DIR="device-mapper.${DEVICE_MAPPER_VER}"
	[ -f "${DEVICE_MAPPER_SRCTAR}" ] || die "Could not find device-mapper source tarball: ${DEVICE_MAPPER_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${DEVICE_MAPPER_DIR}"
	unpack "${DEVICE_MAPPER_SRCTAR}" || die "Failed to unpack device-mapper sources!"
	[ ! -d "${DEVICE_MAPPER_DIR}" ] && die "device-mapper directory ${DEVICE_MAPPER_DIR} invalid"

	cd "${DEVICE_MAPPER_DIR}"
	./configure  --prefix=${TEMP}/device-mapper --enable-static_link >> ${DEBUGFILE} 2>&1 ||
		die 'Configuring device-mapper failed!'
	print_info 1 'device-mapper: >> Compiling...'

	compile_generic utils # Compile
	compile_generic utils 'install'

	cd "${TEMP}"
	rm -rf "${TEMP}/device-mapper/man" || die 'Could not remove manual pages!'
	chmod u+w "${TEMP}/device-mapper/sbin/dmsetup" # Fix crazy permissions to strip
	strip "${TEMP}/device-mapper/sbin/dmsetup" || die 'Could not strip dmsetup binary!'
	genkernel_generate_package "device-mapper.${DEVICE_MAPPER_VER}" device-mapper || die 'Could not tar up the device-mapper binary!'

	rm -rf "${DEVICE_MAPPER_DIR}" > /dev/null
	rm -rf "${TEMP}/device-mapper" > /dev/null
}