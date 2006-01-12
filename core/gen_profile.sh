#!/bin/bash

declare -a __INTERNAL__OPTIONS__KEY # Key
declare -a __INTERNAL__OPTIONS__VALUE # Data
declare -a __INTERNAL__OPTIONS__PROFILE # Profile

profile_copy() {
	# <Source Profile> <Destination Profile (optional)> 

	[ "${1}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	[ "$2" = "" ] && __destination_profile="running" || __destination_profile="$2"
	local identifier values 

	for identifier in $(profile_list_keys $1); do
		# Get raw unprocessed key entry
		values=$(profile_get_key "${identifier}" "${1}" 'true' )
		for i in ${values}
		do
			profile_append_key "${identifier}" "${i}" "${__destination_profile}"
		done
	done
}

profile_list_contents() {
	[ "$1" = "" ] && __destination_profile="running" || __destination_profile="$1"
	local identifier values arg
	for identifier in $(profile_list_keys ${__destination_profile}); do
		echo "${__destination_profile}: ${identifier} \"$(profile_get_key "${identifier}" "${__destination_profile}")\""
	done
}

profile_exists() {
	local n profile array_length=${#__INTERNAL__OPTIONS__KEY[@]}
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		# If it exists return success
		[ "$1" = "${profile}" ] && return 0
	done
	
	# It doesnt exist so return failure
	return 1
}

profile_delete() {
	local key value profile array_length=${#__INTERNAL__OPTIONS__KEY[@]} n z=0
	declare -a __INTERNAL__OPTIONS__KEY_TMP
	declare -a __INTERNAL__OPTIONS__VALUE_TMP
	declare -a __INTERNAL__OPTIONS__PROFILE_TMP

	# Find the items that dont match the profile and save them to a tmp array
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		
		if [  "$1" != "${profile}" ]
		then
			__INTERNAL__OPTIONS__KEY_TMP[${z}]="$key" 
			__INTERNAL__OPTIONS__VALUE_TMP[${z}]="$value"
			__INTERNAL__OPTIONS__PROFILE_TMP[${z}]="$profile"
			let z=${z}+1
		fi

	done
	
	# Clear the original array vars and recreate them
	unset __INTERNAL__OPTIONS__KEY
	unset __INTERNAL__OPTIONS__VALUE
	unset __INTERNAL__OPTIONS__PROFILE

	# Populate arrays from tmp arrays
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY_TMP[@]}; ++n )) ; do
		__INTERNAL__OPTIONS__KEY[${n}]=${__INTERNAL__OPTIONS__KEY_TMP[${n}]}
		__INTERNAL__OPTIONS__VALUE[${n}]=${__INTERNAL__OPTIONS__VALUE_TMP[${n}]}
		__INTERNAL__OPTIONS__PROFILE[${n}]=${__INTERNAL__OPTIONS__PROFILE_TMP[${n}]}
	done
	
	# Clear the tmp arrays
	unset __INTERNAL__OPTIONS__KEY_TMP
	unset __INTERNAL__OPTIONS__VALUE_TMP
	unset __INTERNAL__OPTIONS__PROFILE_TMP
}


profile_list() {
	local myOut n
	local array_length=${#__INTERNAL__OPTIONS__KEY[@]}
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		if ! has "${__INTERNAL__OPTIONS__PROFILE[${n}]}" "${myOut}"
		then
			[ ! "${__INTERNAL__OPTIONS__PROFILE[${n}]}" == "" ] && \
				myOut="${myOut} ${__INTERNAL__OPTIONS__PROFILE[${n}]}"
				myOut="${myOut# }"
				myOut="${myOut% }"

		fi
	done
	echo "${myOut}"
}

profile_delete_key() {
	local key value profile array_length=${#__INTERNAL__OPTIONS__KEY[@]} n __internal_profile z=0
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"
	
	declare -a __INTERNAL__OPTIONS__KEY_TMP
	declare -a __INTERNAL__OPTIONS__VALUE_TMP
	declare -a __INTERNAL__OPTIONS__PROFILE_TMP
	
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		if [ "$1" != "${key}" ]
		then	
			# The keys dont match so these are good to keep
			__INTERNAL__OPTIONS__KEY_TMP[${z}]="$key"
			__INTERNAL__OPTIONS__VALUE_TMP[${z}]="$value"
			__INTERNAL__OPTIONS__PROFILE_TMP[${z}]="$profile"
			let z=${z}+1
		else
			if [ "${__internal_profile}" != "${profile}" ]
			then
				# The keys dont match and the profiles dont match so these are good to keep
				__INTERNAL__OPTIONS__KEY_TMP[${z}]="$key"
				__INTERNAL__OPTIONS__VALUE_TMP[${z}]="$value"
				__INTERNAL__OPTIONS__PROFILE_TMP[${z}]="$profile"
				let z=${z}+1
			fi
		fi
	
	done
	
	# Clear the original array vars
	unset __INTERNAL__OPTIONS__KEY
	unset __INTERNAL__OPTIONS__VALUE
	unset __INTERNAL__OPTIONS__PROFILE

	# Populate arrays from tmp arrays
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY_TMP[@]}; ++n )) ; do
		__INTERNAL__OPTIONS__KEY[${n}]=${__INTERNAL__OPTIONS__KEY_TMP[${n}]}
		__INTERNAL__OPTIONS__VALUE[${n}]=${__INTERNAL__OPTIONS__VALUE_TMP[${n}]}
		__INTERNAL__OPTIONS__PROFILE[${n}]=${__INTERNAL__OPTIONS__PROFILE_TMP[${n}]}
	done
	
	# Clear the tmp arrays
	unset __INTERNAL__OPTIONS__KEY_TMP
	unset __INTERNAL__OPTIONS__VALUE_TMP
	unset __INTERNAL__OPTIONS__PROFILE_TMP
}

profile_list_keys() {
	local key value profile array_length=${#__INTERNAL__OPTIONS__KEY[@]} n __internal_profile myOut
	[ "$1" = "" ] && __internal_profile="running" || __internal_profile="$1"
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		[ "${__internal_profile}" == "${profile}" ] && myOut="${key} ${myOut}"
	done
	echo "${myOut}"
}

setup_system_profile() {
	# has to happen after the cmdline is processed.
	# Read arch-specific config
	ARCH_CONFIG="${CONFIG_DIR}/profile.gk"
	[ -f "${ARCH_CONFIG}" ] && config_profile_read ${ARCH_CONFIG} "system"
	
	# Read the generic kernel modules list first 
	GENERIC_MODULES_LOAD="${CONFIG_GENERIC_DIR}/modules_load.gk"
	[ -f "${GENERIC_MODULES_LOAD}" ] && config_profile_read ${GENERIC_MODULES_LOAD} "system"

	# override with the arch specific kernel modules
	MODULES_LOAD="${CONFIG_DIR}/modules_load.gk"
	[ -f "${MODULES_LOAD}" ] && config_profile_read ${MODULES_LOAD} "system"
}


profile_get_key() {
	# <Key> <Profile (optional)> 
	local n key value profile __internal_profile
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"
	

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		
		if [ "$1" = "${key}" -a "${__internal_profile}" = "${profile}" ]
		then
			# want raw key .. no further processing necessary
			logicTrue ${3} && echo "${value}" && return
			
			# Start building return list
			for i in ${value}; do
				if [ "${i}" == "=" ]
				then
					positive_list=""
					negative_list=""
				elif [ "${i:0:1}" == "-" ]
				then
					if ! has "${i#-}" "${negative_list}"
					then
						negative_list="${negative_list} ${i#-}"
					fi
				else
					if ! has "${i#-}" "${positive_list}"
					then
						positive_list="${positive_list} ${i}"
					fi
				fi
				#echo "i: $i"
				#echo "pl: ${positive_list}"
				#echo "nl: ${negative_list}"
			done
			#echo "pl and nl list created"
			for j in ${negative_list}; do
				positive_list="$(subtract_from_list "$j" "${positive_list}")"
			done
			#echo "fl: ${positive_list}"
			positive_list="${positive_list# }"
			positive_list="${positive_list% }"
			echo "${positive_list}"
			return
		fi

	done
		
}

profile_set_key() {
	# <Key> <Value> <Profile (optional)>
	local n key value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"

	# Check key is not already set, if it is overwrite, else set it.
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
	
		[ "${1}" = "${key}" ] && [ "${__internal_profile}" = "${profile}" ] && \
				__INTERNAL__OPTIONS__VALUE[${n}]="${2}" && \
				return
	done

	# Unmatched
	__INTERNAL__OPTIONS__KEY[${#__INTERNAL__OPTIONS__KEY[@]}]="$1"
	__INTERNAL__OPTIONS__VALUE[${#__INTERNAL__OPTIONS__VALUE[@]}]="$2"
	__INTERNAL__OPTIONS__PROFILE[${#__INTERNAL__OPTIONS__PROFILE[@]}]="$__internal_profile"
}

profile_append_key() {
	# <Key> <Value> <Profile (optional)>
	local n key orig_value new_value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"
	
	# Get raw key
	orig_value="$(profile_get_key ${1} ${__internal_profile} 'true')"
	if ! has $2 ${orig_value}
	then
		new_value="${orig_value} ${2}"
		new_value="${new_value# }"
	else
		new_value="${orig_value}"
	fi

	
	profile_set_key "${1}" "${new_value}" "${__internal_profile}"
}

profile_shrink_key() {
	# <Key> <Value> <Profile (optional)>
	local n key value new_value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"
	
	orig_value="$(profile_get_key ${1} ${__internal_profile})"
	new_value="$(subtract_from_list "$2" "${orig_value}")"
	new_value=${new_value# }
	profile_set_key "${1}" "${new_value}" "${__internal_profile}"
	
	if [[ $(profile_get_key "${1}" "${__internal_profile}") == "" ]]
	then
		profile_delete_key "${1}" "${__internal_profile}"
	fi
}

# <file>
config_profile_read() {
	[ -f "$1" ] || die "parse_profile: No such file $1!"
	local identifier data set_config profile

	if [ -z "$2" ]
	then
		let number_cmdline_profiles=${number_cmdline_profiles}+1
		profile="cmdline-${number_cmdline_profiles}"
	else
		profile="${2}"
	fi
	__INTERNAL_PROFILES_READ="${__INTERNAL_PROFILES_READ} ${1}"
	while read i
	do
		# { identifier }{" := "}{quote}{data}{quote} or
		# "require "{profiles} or
		# "#"{comment}

		# Strip out inline comments
		i="${i/[ 	]\#*/}"

		if [[ "${i}" =~ '^[a-z0-9-]+ [-\+:]= ".*"' ]]
		then
			if [[ "${i}" =~ '^[a-z0-9\-]+ :' ]]
			then
				operator=':'
			elif [[ "${i}" =~ '^[a-z0-9\-]+ -' ]] 
			then
				operator='-'
			else
				operator='+'
			fi
			
			identifier="${i% ${operator}=*}"
			data="${i#*${operator}= \"}" # Remove up to first quote inclusive
			data="${data%\"}" # Remove end quote
			
			case "${operator}" in
				':')
					profile_append_key "${identifier}" "=" "${profile}"
					for j in ${data}
					do
						#echo "appending ${j}"
						profile_append_key "${identifier}" "${j}" "${profile}"
					done
				;;
				'-')
					for j in ${data}
					do
						#echo "appending -${j}"
						profile_append_key "${identifier}" "-${j}" "${profile}"
					done
				;;
				'+')
					for j in ${data}
					do
						#echo "appending ${j}"
						profile_append_key "${identifier}" "${j}" "${profile}"
					done
				;;
			esac

		elif [[ "${i}" =~ '^import ' ]]
		then
			identifier="${i/import /}"
			for j in "${identifier}"
			do
				if has "${j}" "${__INTERNAL_PROFILES_READ}"
				then
					echo "# Cyclic loop detected: ${j} required by ${1} but already processed."
				else
					config_profile_read "${j}" 
				fi
			done
		elif [[ "${i:0:1}" = '#' ]]
		then
			:
		elif [[ "${i}" = '' ]]
		then
			:
		else
			echo "# Invalid input: $i"
		fi
	done < $1

	[ -n "${set_config}" ] && echo "# Profile $1 set config vars:${set_config}"
}

config_profile_dump() {
	local j k separator data profile='user'
	
	for j in $(profile_list_keys "${profile}"); do
		case $j in
			profile|profile-dump)
				:
			;;
			*)
				# Get the raw key data
				data="$(profile_get_key $j "${profile}" 'true')"
				# Append keys by default unless set is specified
				separator="+="
				
				# reset lists to be blank
				element_list=""
				negative_list=""

				# Start building output string from the raw key data
				for k in ${data}; do
					if [ "${k}" == "=" ]
					then
						# use set key notation as an = was found
						element_list=""
						separator=":="
					else

						element_list="${element_list} ${k}"
					fi
				done
				
				for l in ${element_list}; do
					if [ "${l:0:1}" == "-" ]
					then
						negative_list="${negative_list} ${l#-}"
						element_list="$(subtract_from_list "$l" "${element_list}")"
					fi
				done
				
				# Remove items that are in both the positive and negative list as they cancel out
				for m in ${element_list}; do
					for n in ${negative_list}; do
						if [ "${m}" == "${n}" ]
						then
							element_list="$(subtract_from_list "$m" "${element_list}")"
							negative_list="$(subtract_from_list "$m" "${negative_list}")"
						fi
					done
				done
				
				element_list="${element_list# }"
				element_list="${element_list% }"
				negative_list="${negative_list# }"
				negative_list="${negative_list% }"
				
				[ -n "${element_list}" ] && echo "$j ${separator} \"${element_list}\""
				[ -n "${negative_list}" ] && echo "$j -= \"${negative_list}\""

			;;
		esac
	done
	
	exit 0
}

cmdline_modules_register(){
    local i data
    data=$1
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
        profile_append_key "module-${category}" "${i}" "cmdline"
    done
}

