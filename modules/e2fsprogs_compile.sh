# Output: binpackage { / -> blkid }
# Placement: TBD

e2fsprogs_compile::() {
	local E2FSPROGS_DIR="e2fsprogs-${E2FSPROGS_VER}"

	cd "${TEMP}"
	[ ! -f "${E2FSPROGS_SRCTAR}" ] &&
		die "Could not find e2fsprogs source tarball: ${E2FSPROGS_SRCTAR}. Please place it there, or place another version, changing /etc/genkernel.conf as necessary!"

	rm -rf "${E2FSPROGS_DIR}"
	unpack "${E2FSPROGS_SRCTAR}" || die "Could not extract e2fsprogs tarball: ${E2FSPROGS_SRCTAR}"
	[ -d "${E2FSPROGS_DIR}" ] || die "e2fsprogs directory ${E2FSPROGS_DIR} invalid"
	cd "${E2FSPROGS_DIR}"

	print_info 1 'e2fsprogs: >> Configuring...'
	./configure  --with-ldopts=-static >> ${DEBUGFILE} 2>&1 || die 'Configuring e2fsprogs failed!'

	print_info 1 'e2fsprogs: >> Compiling...'
	compile_generic utils # Run make

	print_info 1 'blkid: >> Copying to cache...'
	[ -f "${TEMP}/${E2FSPROGS_DIR}/misc/blkid" ] || die 'Blkid executable does not exist!'
	strip "${TEMP}/${E2FSPROGS_DIR}/misc/blkid" || die 'Could not strip blkid binary!'

	cd misc
	genkernel_generate_package "e2fsprogs-${E2FSPROGS_VER}-blkid.tar.bz2" "./blkid" || die 'Could not generate blkid binary package!'
	cd "${TEMP}"
	rm -rf "${E2FSPROGS_DIR}" > /dev/null
}