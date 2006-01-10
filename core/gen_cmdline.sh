#!/bin/bash

declare -a __INTERNAL__OPTIONS__GROUP # Grouping
declare -a __INTERNAL__OPTIONS__NAME # Option to match
declare -a __INTERNAL__OPTIONS__NEEDE # Need =<data> ?
declare -a __INTERNAL__OPTIONS__HAVEO # Have no<name> variant ?
declare -a __INTERNAL__OPTIONS__SDESC # Short description
declare -a __INTERNAL__OPTIONS__DDEFT # Data default
declare -a __INTERNAL__OPTIONS__FUNC # Callback function for cmdline processing


__register_config_option() {
	# <Group> <Name> <Need data [Bool]> <Have inverse [Bool]> {Description} <callback function (optional)>

	__INTERNAL__OPTIONS__GROUP[${#__INTERNAL__OPTIONS__GROUP[@]}]=$1
	__INTERNAL__OPTIONS__NAME[${#__INTERNAL__OPTIONS__NAME[@]}]=$2
	__INTERNAL__OPTIONS__NEEDE[${#__INTERNAL__OPTIONS__NEEDE[@]}]=${3%%:*}
	__INTERNAL__OPTIONS__HAVEO[${#__INTERNAL__OPTIONS__HAVEO[@]}]=$4
	__INTERNAL__OPTIONS__SDESC[${#__INTERNAL__OPTIONS__SDESC[@]}]=$5
	__INTERNAL__OPTIONS__FUNC[${#__INTERNAL__OPTIONS__FUNC[@]}]=$6

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
	local myRequest myName myTakesData myHasInversion myDataDefault myMatched=false cmdline_profile="cmdline" data
	local kernel_modules category i j
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
					profile_set_key "${myName}" "${myRequest##*\=}" "${cmdline_profile}"
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
				# Special case (kernel-modules) look into changing this to a call back for better generic support"
				if [ "${myRequest%%\=*}" = "--kernel-modules" ]
				then
					if [ ! "${myRequest##*\=}" == "" ]
					then
						data="${myRequest##*\=}"
						if [ "${data}" == "${data%%:*}" ]
						then
							kernel_modules="${data}"
							category="extra"
						else
							kernel_modules="${data##*:}"
							category="${data%%:*}"
						fi
						for j in $kernel_modules
						do
							kernel_modules_register_to_category "${category}" "${j}"
						done
						myMatched=true
					else
						# Nothing behind the = sign
						show_usage
						echo
						echo "Configuration parsing error: '${myRequest}' given but --${myName}= requires an argument!"
						__INTERNAL__CONFIG_PARSING_FAILED=true
					fi
				# On to the regular cases now of true!m
				elif [ ! "${myRequest##*\=}" == "" ]
				then
					if [ "${myName}" = "profile" ]
					then
						config_profile_read ${myRequest##*\=}
						myMatched=true
					else
						profile_set_key "${myName}" "$(profile_get_key ${myName}) ${myRequest##*\=}" "${cmdline_profile}"
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
						profile_set_key "${myName}" "${myDataDefault}" "${cmdline_profile}"
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
					profile_set_key "${myName}" 'true' "${cmdline_profile}"
					myMatched=true
				elif logicTrue ${myHasInversion} && [ "${myRequest}" = "--no-${myName}" ]
				then
					profile_set_key "${myName}" 'false' "${cmdline_profile}"
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
