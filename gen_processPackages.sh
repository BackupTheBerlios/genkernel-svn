genkernel_lookup_packages() {
	local myPkg

	for i in ${CACHE_DIR}/pkg_*.tar.bz2
	do
		[ "${i}" = 'pkg_*.tar.bz2' ] && break

		# Strip directory and extension
		myPkg=${i##*/}
		myPkg=${myPkg%.tar.bz2}

		# Provide
		provide "${myPkg}"
		echo Registering ${myPkg}
	done
}

genkernel_generate_package() {
	tar cjf "${CACHE_DIR}/pkg_$1.tar.bz2" "$2" || gen_die "Could not create binary cache for $1!"
}

genkernel_extract_package() {
	[ -e "${CACHE_DIR}/pkg_$1.tar.bz2" ] || gen_die "Binary cache not present for $1!"
	tar jxf "${CACHE_DIR}/pkg_$1.tar.bz2" || gen_die "Could not extract binary cache for $1!"
}
