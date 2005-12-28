declare -a __INTERNAL__PKG__CALLBACK__S # Source
declare -a __INTERNAL__PKG__CALLBACK__D # Data

package_check_lookup() {
	local target callback

	for (( n = 0 ; n <= ${#__INTERNAL__PKG__CALLBACK__S[@]}; ++n )) ; do
		target=${__INTERNAL__PKG__CALLBACK__S[${n}]}
		callback=${__INTERNAL__PKG__CALLBACK__D[${n}]}

		[ "$1" = "${target}" ] && echo "${callback}" && return
	done
}

# target callback
package_check_register () {
	# Multiple callbacks can be registered on a package.

	for (( n = 0 ; n <= ${#__INTERNAL__PKG__CALLBACK__S[@]}; ++n )) ; do
		if [ "$1" = "${__INTERNAL__PKG__CALLBACK__S[${n}]}" ]
		then
			__INTERNAL__PKG__CALLBACK__D[${n}]="${__INTERNAL__PKG__CALLBACK__D[${n}]} $2"
			return
		fi
	done

	# No luck; add the entry...
	__INTERNAL__PKG__CALLBACK__S[${#__INTERNAL__PKG__CALLBACK__S[@]}]="$1"
	__INTERNAL__PKG__CALLBACK__D[${#__INTERNAL__PKG__CALLBACK__D[@]}]="$2"
}

genkernel_lookup_packages()
{
	local myPkg myCallbacks myCallbacksStatus

	for i in ${CACHE_DIR}/pkg_*.tar.bz2
	do
		[ "${i}" = "${CACHE_DIR}/pkg_*.tar.bz2" ] && break # No matches found
		__INTERNAL__PKG__CALLBACK__STATUS=false # Reset

		# Strip directory and extension
		myPkg=${i##*/}
		myPkg=${myPkg%.tar.bz2}

		# Check for callbacks
		for j in $(package_check_lookup ${myPkg})
		do
			$j			
		done

		# Provide, if things are good
		if [ "${__INTERNAL__PKG__CALLBACK__STATUS}" = "false" ]
		then
			provide "${myPkg}"
			echo Registering ${myPkg}
		fi
	done

	unset __INTERNAL__PKG__CALLBACK__STATUS
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
