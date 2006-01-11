#!/bin/bash

declare -a __INTERNAL__OPTIONS__KEY # Key
declare -a __INTERNAL__OPTIONS__VALUE # Data
declare -a __INTERNAL__OPTIONS__PROFILE # Profile

profile_list_contents() {
	[ "$1" = "" ] && __destination_profile="running" || __destination_profile="$1"
	local identifier values arg
	for identifier in $(profile_list_keys ${__destination_profile}); do
		echo "${__destination_profile}: ${identifier} \"$(profile_get_key "${identifier}" "${__destination_profile}")\""
	done
}

profile_copy() {
	# <Source Profile> <Destination Profile (optional)> 

	[ "${1}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	[ "$2" = "" ] && __destination_profile="running" || __destination_profile="$2"
	local identifier values arg

	for identifier in $(profile_list_keys $1); do
		values=$(profile_get_key "${identifier}" "${1}")
		if has '=' "${values}"
		then
			# Nuke'm
			profile_delete_key "${identifier}" "${__destination_profile}"
		fi
		for arg in $values; do
			if [ "${arg}" == "=" ]
			then
				:
			elif [ "${arg:0:1}" == "-" ]
			then
				profile_shrink_key "${identifier}" "${arg#-}" "${__destination_profile}"
			else
				profile_append_key "${identifier}" "${arg}" "${__destination_profile}"
			fi
		done
		#typeset -p __INTERNAL__OPTIONS__KEY # Key
		#typeset -p __INTERNAL__OPTIONS__VALUE # Key
		#typeset -p __INTERNAL__OPTIONS__PROFILE # Key
		#echo "${__destination_profile}: ${identifier} \"$(profile_get_key "${identifier}" "${__destination_profile}")\""
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

import_arch_profile() {
	CACHE_DIR="$(arch_replace ${CACHE_DIR})"
	CONFIG_DIR="$(arch_replace ${CONFIG_DIR})"
	[ -e "${CACHE_DIR}" ] || mkdir -p "${CACHE_DIR}"
	[ -e "${CONFIG_DIR}" ] || mkdir -p "${CONFIG_DIR}"

	# Read arch-specific config
	ARCH_CONFIG="${CONFIG_DIR}/profile.gk"
	[ -f "${ARCH_CONFIG}" ] && config_profile_read ${ARCH_CONFIG} "arch"
	
	# Copy the arch profile we just imported into the arch profile	
	setup_arch_profile
}

setup_arch_profile() {
    PREFIX='arch'
    for i in $(profile_list); do
        [ "${i:0:${#PREFIX}}" = ${PREFIX} ] && profile_copy $i "arch" && profile_delete $i
    done
}

setup_userspace() {
    # Create the userspace profile
    PREFIX='profile'
    profile_delete "profile"
    for i in $(profile_list); do
        [ "${i:0:${#PREFIX}}" = ${PREFIX} ] && profile_copy $i $PREFIX
    done

    profile_delete "user"
    profile_copy "profile" "user"
    profile_copy "cmdline" "user"
}

profile_get_key() {
	# <Key> <Profile (optional)> 
	local n key value profile __internal_profile
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		[ "$1" = "${key}" ] && [ "${__internal_profile}" = "${profile}" ] && echo "${value}" && return
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
	local n key value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"

	orig_key="$(profile_get_key ${1} ${__internal_profile})"
	
	new_key="${orig_key} ${2}"
	new_key="${new_key# }"
	
	profile_set_key "${1}" "${new_key}" "${__internal_profile}"
}

profile_shrink_key() {
	# <Key> <Value> <Profile (optional)>
	local n key value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"
	
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		
		if [ "${1}" = "${key}" -a "${__internal_profile}" = "${profile}" ]
		then
			new_value="$(subtract_from_list "$2" "${value}")"
			new_value=${new_value# }
			__INTERNAL__OPTIONS__VALUE[${n}]="${new_value}"
		fi
	done
}

import_kernel_module_load_list() {
	# Read the generic modules list first 
	GENERIC_MODULES_LOAD="${CONFIG_GENERIC_DIR}/modules_load"
	[ -f "${GENERIC_MODULES_LOAD}" ] && config_profile_read ${GENERIC_MODULES_LOAD} "modules"

	# override with the arch specific one
	MODULES_LOAD="${CONFIG_DIR}/modules_load"
	[ -f "${MODULES_LOAD}" ] && config_profile_read ${MODULES_LOAD} "modules"
}	


# <file>
config_profile_read() {
	[ -f "$1" ] || die "parse_profile: No such file $1!"
	# If prefix is not specified default to profile
	[ -z "$2" ] && PROFILE_PREFIX="profile" || PROFILE_PREFIX="${2}"

	local identifier data set_config profile

	# replace /'s with _'s to create a new profile name
	profile="${PROFILE_PREFIX}_${1//\//_}"
	
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

			#if [[ "${identifier:0:7}" = 'module_' ]]
			#then
			#	identifier="${identifier:7}"
			#	# Append the data into the modules profile space.
			#	kernel_modules_register_to_category "${identifier}" "${data}"
			if [[ "${identifier:0:16}" = 'genkernel_module' ]]
			then
				__INTERNAL__CONFIG_PARSING_DEPTREE="${__INTERNAL__CONFIG_PARSING_DEPTREE} ${data}"
			else
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
				#echo "${identifier} \"$(profile_get_key "${identifier}" "${profile}")\""
			fi

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
	done < "$1"

	[ -n "${set_config}" ] && echo "# Profile $1 set config vars:${set_config}"
}

config_profile_dump() {
	local n
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		case "${__INTERNAL__OPTIONS__KEY[${n}]}" in
			profile|profile-dump)
				:
			;;
			*)
				[ "${__INTERNAL__OPTIONS__PROFILE[${n}]}" == 'user' ] && \
					echo "${__INTERNAL__OPTIONS__KEY[${n}]} := \"${__INTERNAL__OPTIONS__VALUE[${n}]}\""
			;;
		esac
	done
	echo "genkernel_module := \"${__INTERNAL__CONFIG_PARSING_DEPTREE}\""
	exit 0
}

