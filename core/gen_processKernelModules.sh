declare -a __INTERNAL__MODULES__C # Category
declare -a __INTERNAL__MODULES__D # Modules list

kernel_modules_category_lookup() {
	local category data

	for (( n = 0 ; n <= ${#__INTERNAL__MODULES__C[@]}; ++n )) ; do
		category=${__INTERNAL__MODULES__C[${n}]}
		data=${__INTERNAL__MODULES__D[${n}]}

		[ "$1" = "${category}" ] && echo "${data}" && return
	done
}

# category modules
kernel_modules_register_to_category () {
	# See if category is already defined and if so append to it
	for (( n = 0 ; n <= ${#__INTERNAL__MODULES__C[@]}; ++n )) ; do
		if [ "$1" = "${__INTERNAL__MODULES__C[${n}]}" ]
		then
			# FIXME: Perform negations if needed here...
			__INTERNAL__MODULES__D[${n}]="${__INTERNAL__MODULES__D[${n}]} $2"
			return
		fi
	done

	# No luck; add the entry...
	__INTERNAL__MODULES__C[${#__INTERNAL__MODULES__C[@]}]="$1"
	__INTERNAL__MODULES__D[${#__INTERNAL__MODULES__D[@]}]="$2"
}
