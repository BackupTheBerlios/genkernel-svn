require @pkg_klibc-${KLIBC_VER}:null:klibc_compile

klibc::()
{
	cd ${TEMP}
	genkernel_extract_package "klibc-${KLIBC_VER}"

	# Export KLCC location for udev and others
	KLCC="${TEMP}/klibc-build-${KLIBC_VER}/bin/klcc"
}
