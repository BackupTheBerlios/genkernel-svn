genkernel_lookup_packages()
{
	local myPkg

	for i in ${CACHE_DIR}/pkg_*.tar.bz2
	do
		[ "${i}" = "${CACHE_DIR}/pkg_*.tar.bz2" ] && break # No matches found

		# Strip directory and extension
		myPkg=${i##*/}
		myPkg=${myPkg%.tar.bz2}

		# Provide
		provide "${myPkg}"
		echo Registering ${myPkg}
	done
}

genkernel_generate_cpio() {
	cpio --quiet -o -H newc | gzip -9 > "${TEMP}/$1.cpio.gz"
}

genkernel_generate_cpio_path() {
	find $2 -print | genkernel_generate_cpio "$1"
}

genkernel_generate_cpio_files() {
	local name=$1
	shift

	print_list $* | genkernel_generate_cpio "${name}"
}

genkernel_generate_package() {
	tar cjf "${CACHE_DIR}/pkg_$1.tar.bz2" "$2" || die "Could not create binary cache for $1!"
}

genkernel_extract_package() {
	[ -e "${CACHE_DIR}/pkg_$1.tar.bz2" ] || die "Binary cache not present for $1!"
	tar jxf "${CACHE_DIR}/pkg_$1.tar.bz2" || die "Could not extract binary cache for $1!"
}

unpack()
{
	local tarFlags
	[ -e "$1" ] || die "File to unpack not present: $1!"

	case "$1" in
		*.tar.bz2)
			tarFlags='j'
		;;
		*.tgz|*.tar.gz)
			tarFlags='z'
		;;
		*.tar)
			false
		;;
		*)
			die "Unrecognized filetype to unpack: $1!"
		;;
	esac

	print_info 1 "unpack: Processing $1..."
	tar ${tarFlags}xpf "$1" || die "Failed to unpack $1!"
}
