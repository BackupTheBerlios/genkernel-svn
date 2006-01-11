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
			if [ "${2:0:1}" == "-" ]
			then
				# Remove module to be loaded 
				__INTERNAL__MODULES__D[${n}]="${__INTERNAL__MODULES__D[${n}]/${2:1}/}"
			else
				# Add  module to be loaded
				__INTERNAL__MODULES__D[${n}]="${__INTERNAL__MODULES__D[${n}]} $2"
			fi
			return
		fi
	done

	# No luck; add the entry...
	if [ ! "${2:0:1}" == "-" ]
	then
		__INTERNAL__MODULES__C[${#__INTERNAL__MODULES__C[@]}]="$1"
		__INTERNAL__MODULES__D[${#__INTERNAL__MODULES__D[@]}]="$2"
	fi
}

kernel_modules_category_list() {
    local myOut n
    local array_length=${#__INTERNAL__MODULES__C[@]}
    for (( n = 0 ; n < ${array_length}; ++n )) ; do
        if ! has "${__INTERNAL__MODULES__C[${n}]}" "${myOut}"
        then
            [ ! "${__INTERNAL__MODULES__C[${n}]}" == "" ] && \
                myOut="${__INTERNAL__MODULES__C[${n}]} ${myOut}"
        fi
    done
    echo "${myOut}"
}

cmdline_modules_register(){
	local i data
	data=$1
	echo $data
	if [ "${data}" == "${data%:*}" ]
	then
		kernel_modules="${data}"
		category="extra"
	else
		kernel_modules="${data#*:}"
		category="${data%:*}"
	fi

	for i in $kernel_modules
	do
		profile_append_key "${category}" "${i}" "modules-cmdline"
	done
}
