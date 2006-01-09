#!/bin/bash

declare -a __INTERNAL__OPTIONS__GROUP # Grouping
declare -a __INTERNAL__OPTIONS__NAME # Option to match
declare -a __INTERNAL__OPTIONS__NEEDE # Need =<data> ?
declare -a __INTERNAL__OPTIONS__HAVEO # Have no<name> variant ?
declare -a __INTERNAL__OPTIONS__SDESC # Short description
declare -a __INTERNAL__OPTIONS__DDEFT # Data default

declare -a __INTERNAL__OPTIONS__KEY # Key
declare -a __INTERNAL__OPTIONS__VALUE # Data
declare -a __INTERNAL__OPTIONS__PROFILE # Profile

profile_copy() {
	# <Source Profile> <Destination Profile (optional)> 

	[ "${1}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	local key value profile array_length n
	
	declare -a __INTERNAL_TMP_KEY=( ${__INTERNAL__OPTIONS__KEY[@]} )
	declare -a __INTERNAL_TMP_VALUE=( ${__INTERNAL__OPTIONS__VALUE[@]} )
	declare -a __INTERNAL_TMP_PROFILE=( ${__INTERNAL__OPTIONS__PROFILE[@]} )

	array_length=${#__INTERNAL_TMP_KEY[@]}
	
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		key=${__INTERNAL_TMP_KEY[${n}]}
		value=${__INTERNAL_TMP_VALUE[${n}]}
		profile=${__INTERNAL_TMP_PROFILE[${n}]}
		if [ "${1}" == "${profile}" ] 
		then
			config_set_key "${key}" "${value}" "${2}"
		fi
	done
	
	# Delete temporary arrays
	unset __INTERNAL_TMP_KEY
	unset __INTERNAL_TMP_VALUE
	unset __INTERNAL_TMP_PROFILE
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
	local key value profile array_length=${#__INTERNAL__OPTIONS__KEY[@]} x=0 n
	declare -a __INTERNAL_TMP_KEY	
	declare -a __INTERNAL_TMP_VALUE
	declare -a __INTERNAL_TMP_PROFILE	
	
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		[ ! "$1" == "${profile}" ] && \
			__INTERNAL_TMP_KEY[${x}]=${__INTERNAL__OPTIONS__KEY[${n}]} && \
			__INTERNAL_TMP_VALUE[${x}]=${__INTERNAL__OPTIONS__VALUE[${n}]} && \
			__INTERNAL_TMP_PROFILE[${x}]=${__INTERNAL__OPTIONS__PROFILE[${n}]} && \
			let "x = $x + 1"
	done

	# Reset arrays to temporary values
	__INTERNAL__OPTIONS__KEY=( ${__INTERNAL_TMP_KEY[@]} )
	__INTERNAL__OPTIONS__VALUE=( ${__INTERNAL_TMP_VALUE[@]} )
	__INTERNAL__OPTIONS__PROFILE=( ${__INTERNAL_TMP_PROFILE[@]} )
	
	# Delete temporary arrays
	unset __INTERNAL_TMP_KEY
	unset __INTERNAL_TMP_VALUE
	unset __INTERNAL_TMP_PROFILE
}

profile_list() {
	local myOut n
	local array_length=${#__INTERNAL__OPTIONS__KEY[@]}
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		if ! has "${__INTERNAL__OPTIONS__PROFILE[${n}]}" "${myOut}"
		then
			[ ! "${__INTERNAL__OPTIONS__PROFILE[${n}]}" == "" ] && \
				myOut="${__INTERNAL__OPTIONS__PROFILE[${n}]} ${myOut}"
		fi
	done
	echo "${myOut}"
}

import_arch_profile() {
	CACHE_DIR="$(arch_replace ${CACHE_DIR})"
	CONFIG_DIR="$(arch_replace ${CONFIG_DIR})"
	[ -e "${CACHE_DIR}" ] || mkdir -p "${CACHE_DIR}"
	[ -e "${CONFIG_DIR}" ] || mkdir -p "${CONFIG_DIR}"

	# Read arch-specific config
	ARCH_CONFIG="${CONFIG_DIR}/profile.sh"
	[ -f "${ARCH_CONFIG}" ] && config_profile_read ${ARCH_CONFIG} "arch"
	
	# Copy the arch profile we just imported into the arch profile	
	setup_arch_profile
}

config_get_key() {
	# <Key> <Profile (optional)> 
	###<Return on lookup failure (Bool)> Disabled for profile feature 
	local key value __internal_profile n	
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
		[ "$1" = "${key}" ] && [ "${__internal_profile}" = "${profile}" ] && echo "${value}" && return
	done
	#logicTrue $2 && echo 'error::lookup-failure'
}

config_set_key() {
	# <Key> <Value> <Profile (optional)>
	local n
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"

	# Check key is not already set, if it is overwrite, else set it.
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}

		[ "$1" = "${key}" ] && [ "${__internal_profile}" = "${profile}" ] && __INTERNAL__OPTIONS__VALUE[${n}]=$2 && return
	done

	# Unmatched
	# echo "$1 $2 $__internal_profile"
	__INTERNAL__OPTIONS__KEY[${#__INTERNAL__OPTIONS__KEY[@]}]=$1
	__INTERNAL__OPTIONS__VALUE[${#__INTERNAL__OPTIONS__VALUE[@]}]=$2
	__INTERNAL__OPTIONS__PROFILE[${#__INTERNAL__OPTIONS__PROFILE[@]}]=$__internal_profile
}

__register_config_option() {
	# <Group> <Name> <Need data [Bool]> <Have inverse [Bool]> {Description} 

	__INTERNAL__OPTIONS__GROUP[${#__INTERNAL__OPTIONS__GROUP[@]}]=$1
	__INTERNAL__OPTIONS__NAME[${#__INTERNAL__OPTIONS__NAME[@]}]=$2
	__INTERNAL__OPTIONS__NEEDE[${#__INTERNAL__OPTIONS__NEEDE[@]}]=${3%%:*}
	__INTERNAL__OPTIONS__HAVEO[${#__INTERNAL__OPTIONS__HAVEO[@]}]=$4
	__INTERNAL__OPTIONS__SDESC[${#__INTERNAL__OPTIONS__SDESC[@]}]=$5

	# See if we have a default specified
	if [ "${3/:/}" != "${3}" ]
	then
		__INTERNAL__OPTIONS__DDEFT[${#__INTERNAL__OPTIONS__DDEFT[@]}]=${3##*:}
	else
		__INTERNAL__OPTIONS__DDEFT[${#__INTERNAL__OPTIONS__DDEFT[@]}]=''
	fi
}

show_help__internal__tabulation_lookup() {
	local n name count

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__GCOUNTER__NAME[@]}; ++n )) ; do
		name=${__INTERNAL__OPTIONS__GCOUNTER__NAME[${n}]}
		count=${__INTERNAL__OPTIONS__GCOUNTER__COUNT[${n}]}

		[ "$1" = "${name}" ] && echo "${n}" && return
        done
}

show_help__internal__generate_tabs() {
	local n
	for (( n = 0 ; n < $1; ++n )) ; do
		echo -n "	"
	done
}

show_help() {
	echo "${GOOD}>> ${BOLD}Gentoo Linux Genkernel${NORMAL}; Version ${GK_V}${NORMAL}"
	echo "   ${GOOD}Usage:${NORMAL}"
	echo "		${BOLD}genkernel [options] module${NORMAL}"

	local myCols myTCols myOldGroup myName myGroup myTakesData myHasInversion myDescription myFPrint myPrint myLChar myTabLen myWrapped

	myCols="$(tput cols)"
	myCols=${myCols:=80} # Failsafe to 80 cols.

	# Force a minimum column width so it looks sane
	if [ "${myCols}" -le '50' ]
	then
		echo "Error: Need a terminal of at least 50 columns."
		exit 1
	fi

	myCols=$((${myCols}-18)) # Subtract leading two tabs and spaces
	declare -a __INTERNAL__OPTIONS__GCOUNTER__NAME
	declare -a __INTERNAL__OPTIONS__GCOUNTER__COUNT

	# Iterate over the items; then either set or adjust the stored maximum
	# group length as needed for tabulation.
	for (( i = 0 ; i < ${#__INTERNAL__OPTIONS__NAME[@]}; ++i )) ; do
		myOldGroup=${__INTERNAL__OPTIONS__GROUP[${i}]}
		myName=${__INTERNAL__OPTIONS__NAME[${i}]}
		myDescription=${__INTERNAL__OPTIONS__SDESC[${i}]}
		myTakesData=${__INTERNAL__OPTIONS__NEEDE[${i}]}

		# Lookup if already processed
		myGroup=$(show_help__internal__tabulation_lookup "${myOldGroup}")
		logicTrue "${myTakesData}" && myLChar=6 || myLChar=0
		myLChar="$((${myLChar} + ${#myName} + 2))"
		[ "$(( ${myLChar} % 8 ))" -eq '0' ] && myLChar="$((${myLChar} + 8))"

		if [ -n "${myGroup}" ]
		then
			if [ "${__INTERNAL__OPTIONS__GCOUNTER__COUNT[${myGroup}]}" -lt "${myLChar}" -a "${#myDescription}" -lt "${myCols}" ]
			then
				__INTERNAL__OPTIONS__GCOUNTER__COUNT[${myGroup}]=${myLChar}
			fi
		else
			__INTERNAL__OPTIONS__GCOUNTER__NAME[${#__INTERNAL__OPTIONS__GCOUNTER__NAME[@]}]=${myOldGroup}
			__INTERNAL__OPTIONS__GCOUNTER__COUNT[${#__INTERNAL__OPTIONS__GCOUNTER__COUNT[@]}]=${myLChar}
		fi
	done

	for (( i = 0 ; i < ${#__INTERNAL__OPTIONS__NAME[@]}; ++i )) ; do
		myOldGroup=${myGroup}
		myGroup=${__INTERNAL__OPTIONS__GROUP[${i}]}
		myTakesData=${__INTERNAL__OPTIONS__NEEDE[${i}]}
		myHasInversion=${__INTERNAL__OPTIONS__HAVEO[${i}]}
		myDescription=${__INTERNAL__OPTIONS__SDESC[${i}]}
		[ -z "${myDescription}" ] && continue # Hidden items
		[ "${myOldGroup}" != "${myGroup}" ] && echo "   ${GOOD}${myGroup}${NORMAL}"

		myWrapped=''
		myPrint='--'
		myFPrint='--'
		if logicTrue "${myHasInversion}"
		then
			myFPrint="${myPrint}[${WARN}no-${BOLD}]"
			myPrint="${myPrint}[no-]"
		fi

		myPrint="${myPrint}${__INTERNAL__OPTIONS__NAME[${i}]}"
		myFPrint="${myFPrint}${__INTERNAL__OPTIONS__NAME[${i}]}"
		if logicTrue "${myTakesData}"
		then
			myFPrint="${myFPrint}=<...>"
			myPrint="${myPrint}=<...>"
		fi
		
		if [ "${myTakesData}" == 'true!m' ]
		then
			myFPrint="${myFPrint}=<...> (multiple)"
			myPrint="${myPrint}=<...> (multiple)"
		fi

		# Work out tab lengths:
		myTabLen=$(show_help__internal__tabulation_lookup "${myGroup}") # Fetch
		myTabLen=${__INTERNAL__OPTIONS__GCOUNTER__COUNT[${myTabLen}]}
#		echo -n "Out: ${myTabLen} ag. ${#myPrint}"

		myTabLen=$(( (8 - ($myTabLen % 8)) - (($myTabLen % 8 == 0) * 8) + ${myTabLen} )) # Round up to tab position we need to push this to
		myTabLen=$(( ((${myTabLen} - ${#myPrint})/8) + (((${myTabLen} - ${#myPrint}) % 8) > 0) )) # Get delta, work out tab number
		myTCols=$(( ${myCols} - ${myTabLen}*8 - ${#myPrint} ))
#		echo ":: ${myTabLen}"
		[ "${myTabLen}" -eq '0' ] && myTabLen=1

		echo -n "		${BOLD}${myFPrint}${NORMAL}"

		while [ "${#myDescription}" -ne 0 ]
		do
			# Wrap over onto the next line; check if last char is space or data is less than next line.
			myLChar=${myDescription[${myCols}]}
			if [ "${#myDescription}" -ge "${myTCols}" -o "${myWrapped}" = 'force' ]
			then
				case "${myLChar}" in
					'.'|' '|';'|':'|'!')
						# EOL; no wrap.
						echo "		${myDescription:0:${myCols}}"
						myDescription="${myDescription:${myCols}}" # Next line
					;;
					*)
						# Wrap over.

						if [ "${#myDescription}" -le "${myCols}" ]
						then
							[ -z "${myWrapped}" -o "${myWrapped}" = 'force' ] && echo
							echo "		  ${myDescription}"
							myDescription=''
#							myWrapped='true'
						else
							[ -z "${myWrapped}" ] && echo && myWrapped='true'

							myLChar="${myDescription:0:${myCols}}"
							myDescription="${myLChar##* }${myDescription:${myCols}}"
							echo "		  ${myLChar% *}"
						fi
					;;
				esac
			else
				[ -n "${myWrapped}" ] && echo "		  ${myDescription}" || echo "$(show_help__internal__generate_tabs ${myTabLen})${myDescription}"
				myDescription=''
			fi
		done
	done
	exit 0
}

show_usage() {
  echo "Gentoo Linux Genkernel ${GK_V}"
  echo "Usage: "
  echo "	genkernel [options] [module::]+"
  echo
  echo 'For a detailed list of supported options, flags and modules; issue:'
  echo '	genkernel --help'
}

# Match $* against configuration registry and process...
parse_cmdline() {
	# Iterate over each registered config option and see if we have a match.
	local myRequest myName myTakesData myHasInversion myDataDefault myMatched=false cmdline_profile="cmdline"

	myRequest=$*
	for (( i = 0 ; i < ${#__INTERNAL__OPTIONS__NAME[@]}; ++i )) ; do
		myName=${__INTERNAL__OPTIONS__NAME[${i}]}
		myTakesData=${__INTERNAL__OPTIONS__NEEDE[${i}]}
		myHasInversion=${__INTERNAL__OPTIONS__HAVEO[${i}]}
		myDataDefault=${__INTERNAL__OPTIONS__DDEFT[${i}]}

		# See if we have data and check we have a match of the option
		if [ "${myRequest/\=/}" != "${myRequest}" -a "${myRequest%%\=*}" = "--${myName}" ]
		then
			if logicTrue ${myTakesData}
			then
				if [ ! "${myRequest##*\=}" == "" ]
				then
					config_set_key "${myName}" "${myRequest##*\=}" "${cmdline_profile}"
					myMatched=true
				else
					# Nothing behind the = sign
					show_usage
					echo
					echo "Configuration parsing error: '${myRequest}' given but --${myName}= requires an argument!"
					__INTERNAL__CONFIG_PARSING_FAILED=true
					return 1
				fi

			elif [ "${myTakesData}" = 'true!m' ]
			then
				if [ ! "${myRequest##*\=}" == "" ]
				then
					if [ "${myName}" = "profile" ]
					then
						config_profile_read ${myRequest##*\=}
						myMatched=true
					else
						config_set_key "${myName}" "$(config_get_key ${myName}) ${myRequest##*\=}" "${cmdline_profile}"
						myMatched=true
					fi
				else
					# Nothing behind the = sign
					show_usage
					echo
					echo "Configuration parsing error: '${myRequest}' given but --${myName}= requires an argument!"
					__INTERNAL__CONFIG_PARSING_FAILED=true
					return 1
				fi
			else
				# Data but we don't take data!
				show_usage
				echo
				echo "Configuration parsing error: '${myRequest}' given but --${myName} does not take arguments!"
				__INTERNAL__CONFIG_PARSING_FAILED=true
				return 1
			fi
		else
			# See if we have a module specification
			if [ "${myRequest:(-2)}" = '::' ]
			then
				# Add to deptree
				__INTERNAL__CONFIG_PARSING_DEPTREE="${__INTERNAL__CONFIG_PARSING_DEPTREE} ${myRequest%::}"
				myMatched=true
			elif logicTrue ${myTakesData}
			then
				if [ "${myRequest}" = "--${myName}" ]
				then
					if [ -n "${myDataDefault}" ]
					then
						config_set_key "${myName}" "${myDataDefault}" "${cmdline_profile}"
						myMatched=true
					else
						show_usage
						echo
						echo "Configuration parsing error: --${myName} requires an argument!"
						__INTERNAL__CONFIG_PARSING_FAILED=true
						return 1
					fi
				fi
			else
				if [ "${myRequest}" = "--${myName}" ]
				then
					config_set_key "${myName}" 'true' "${cmdline_profile}"
					myMatched=true
				elif logicTrue ${myHasInversion} && [ "${myRequest}" = "--no-${myName}" ]
				then
					config_set_key "${myName}" 'false' "${cmdline_profile}"
					myMatched=true
				# else: We are unmatched...
				fi
			fi
		fi

		[ "${myMatched}" != 'false' ] && break
	done

	if [ "${myMatched}" = 'false' ]
	then
		show_usage
		echo
		echo "Configuration parsing error: Invalid request '${myRequest}'."
		__INTERNAL__CONFIG_PARSING_FAILED=true
		return 1
	fi
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

		if [[ "${i}" =~ '[a-z\-]+ := \".*\"$' ]]
		then
			identifier="${i% :=*}"
			data="${i#*:= \"}" # Remove up to first quote inclusive
			data="${data%\"}" # Remove end quote
			if [[ "${identifier:0:7}" = 'module_' ]]
			then
				identifier="${identifier:7}"
				# Call module merge here; a '-module' in the module list will
				# remove the module if it already is added; otherwise add the
				# module to the list.
			elif [[ "${identifier:0:16}" = 'genkernel_module' ]]
			then
				__INTERNAL__CONFIG_PARSING_DEPTREE="${__INTERNAL__CONFIG_PARSING_DEPTREE} ${data}"
			else
				set_config="${set_config} ${identifier}"
				config_set_key "${identifier}" "${data}" "${profile}"
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
