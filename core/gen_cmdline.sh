#!/bin/bash

declare -a __INTERNAL__OPTIONS__GROUP # Grouping
declare -a __INTERNAL__OPTIONS__NAME # Option to match
declare -a __INTERNAL__OPTIONS__NEEDE # Need =<data> ?
declare -a __INTERNAL__OPTIONS__HAVEO # Have no<name> variant ?
declare -a __INTERNAL__OPTIONS__SDESC # Short description
declare -a __INTERNAL__OPTIONS__DDEFT # Data default

declare -a __INTERNAL__OPTIONS__KEY # Key
declare -a __INTERNAL__OPTIONS__VALUE # Data

config_get_key() {
	# <Key> <Return on lookup failure (Bool)>
	local key value

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}

		[ "$1" = "${key}" ] && echo "${value}" && return
        done
	logicTrue $2 && echo 'error::lookup-failure'
}

config_set_key() {
	# <Key> <Value>

	# Check key is not already set, if it is overwrite, else set it.
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}

		[ "$1" = "${key}" ] && __INTERNAL__OPTIONS__VALUE[${n}]=$2 && return
        done

	# Unmatched
	__INTERNAL__OPTIONS__KEY[${#__INTERNAL__OPTIONS__KEY[@]}]=$1
	__INTERNAL__OPTIONS__VALUE[${#__INTERNAL__OPTIONS__VALUE[@]}]=$2
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
	local name count

	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__GCOUNTER__NAME[@]}; ++n )) ; do
		name=${__INTERNAL__OPTIONS__GCOUNTER__NAME[${n}]}
		count=${__INTERNAL__OPTIONS__GCOUNTER__COUNT[${n}]}

		[ "$1" = "${name}" ] && echo "${n}" && return
        done
}

show_help__internal__generate_tabs() {
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
  echo "	genkernel [options] [::module...]+"
  echo
  echo 'For a detailed list of supported options, flags and modules; issue:'
  echo '	genkernel --help'
}

#  GROUP -> OPTION -> DATA (Boolean):[DEFAULT] -> Allow no'X' (Boolean) -> DESCRIPTION
## Debug
__register_config_option 'Debug' 'debuglevel' 'true' 'false' 'Debug verbosity level'
__register_config_option 'Debug' 'debugfile'  'true' 'false' 'Output file for debug info'

## Kernel Config
__register_config_option 'Kernel Configuration'	'menuconfig'	 'false' 'true'	 'Run menuconfig after oldconfig.'
__register_config_option 'Kernel Configuration'	'no-save-config' 'false' 'false' "Don't save the configuration to /etc/kernels."
__register_config_option 'Kernel Configuration'	'gconfig'	 'false' 'false' 'Run gconfig after oldconfig.'
__register_config_option 'Kernel Configuration'	'xconfig'	 'false' 'false' 'Run xconfig after oldconfig.'

## Kernel Compile
__register_config_option 'Kernel Compile' 'clean'		'false'	'true'	'Run "make clean" before compilation.'
__register_config_option 'Kernel Compile' 'install'		'false' 'true'	'Install the kernel to /boot after building; this does not change bootloader settings.'
__register_config_option 'Kernel Compile' 'mrproper'		'false' 'true'	'Run "make mrproper" before compilation.'
__register_config_option 'Kernel Compile' 'oldconfig'		'false' 'false' 'Implies "--no-clean" and runs a "make oldconfig".'
__register_config_option 'Kernel Compile' 'gensplash'		'true:true' 'false' 'Install gensplash support into bzImage optionally using the specified theme.'

## Kernel Settings
__register_config_option 'Kernel Settings' 'kernel-config' 'true' 'false' 'Kernel configuration file to use for compilation.'
__register_config_option 'Kernel Settings' 'kernel-tree'   'true' 'false' 'Location of kernel sources.'
__register_config_option 'Kernel Settings' 'module-prefix' 'true' 'false' 'Prefix to kernel module destination, modules will be installed in <prefix>/lib/modules.'

## Low Level Kernel
# __register_config_option 'Low-Level' 'kernel-as' 'true' 'false' 'Assembler to use for kernel.'
# __register_config_option 'Low-Level' 'kernel-cc' 'true' 'false' 'Compiler to use for kernel.'
# __register_config_option 'Low-Level' 'kernel-ld' 'true' 'false' 'Linker to use for kernel.'
__register_config_option 'Low-Level' 'kernel-cross-compile' 'true' 'false' 'CROSS_COMPILE kernel variable.'
# __register_config_option 'Low-Level' 'kernel-make' 'true' 'false' 'Make to use for kernel.'

## Low Level Utils
# __register_config_option 'Low-Level' 'utils-as' 'true' 'false' 'Assembler to use for utilities.'
# __register_config_option 'Low-Level' 'utils-cc' 'true' 'false' 'Compiler to use for utilities.'
# __register_config_option 'Low-Level' 'utils-ld' 'true' 'false' 'Linker to use for utilities.'
# __register_config_option 'Low-Level' 'utils-make' 'true' 'false' 'Make to use for kernel.'

## Low Level Misc
__register_config_option 'Low-Level' 'makeopts' 'true' 'false' 'Global make options.'

## Init
__register_config_option 'Initialization' 'bootloader=grub' 'false' 'false' 'Add new kernel to GRUB configuration.'
__register_config_option 'Initialization' 'do-keymap-auto' 'false' 'false' 'Force keymap selection at boot.'
__register_config_option 'Initialization' 'evms2' 'false' 'false' 'Include EVMS2 support.'
__register_config_option 'Initialization' 'lvm2' 'false' 'false' 'Include LVM2 support.'
__register_config_option 'Initialization' 'disklabel' 'false' 'false' 'Include disk label and uuid support in your initramfs.'
__register_config_option 'Initialization' 'linuxrc' 'true' 'false' 'Use a user specified linuxrc.'
__register_config_option 'Initialization' 'gensplash-res' 'true' 'false' 'Gensplash resolutions to include; this is passed to splash_geninitramfs in the "-r" flag.'

## Catalyst Init Internals
__register_config_option 'Initialization' 'bladecenter' 'false' 'false' '' # Used by catalyst internally, hide option; 'Enables extra pauses for IBM Bladecenter CD boots.'
__register_config_option 'Initialization' 'unionfs' 'false' 'false' '' # Description empty, hide option

## Internals
__register_config_option 'Internals' 'arch-override' 'true' 'false' 'Force to arch instead of autodetecting.'
__register_config_option 'Internals' 'callback'	'true' 'false' 'Run the specified arguments after the kernel and modules have been compiled.'
__register_config_option 'Internals' 'cachedir' 'true' 'false' 'Override the default cache location.'
__register_config_option 'Internals' 'tempdir' 'true' 'false' "Location of Genkernel's temporary directory."
__register_config_option 'Internals' 'postclear' 'false' 'false' 'Clear all temporary files and caches afterwards.'
__register_config_option 'Internals' 'profile' 'true!m' 'false' 'Use specified profile.'
__register_config_option 'Internals' 'profile-dump' 'false' 'false' 'Use specified profile.'
__register_config_option 'Internals' 'mountboot' 'false' 'true' 'Mount /boot automatically.'
__register_config_option 'Internals' 'usecolor' 'false' 'true' 'Color output.'

## Output Settings
__register_config_option 'Output Settings' 'kerncache' 'true' 'false' "File to output a .tar.bz2'd kernel, the contents of /lib/modules/ and the kernel config; this is done before callbacks."
__register_config_option 'Output Settings' 'kernel-name' 'true' 'false' 'Tag the kernel and initrd with a name; if not defined the option defaults to "genkernel".'
__register_config_option 'Output Settings' 'initramfs-overlay' 'true' 'false' 'Directory structure to include in the initramfs.'
__register_config_option 'Output Settings' 'minkernpackage' 'true' 'false' "File to output a .tar.bz2'd kernel and initrd: No modules outside of the initrd will be included..."
__register_config_option 'Output Settings' 'modulespackage' 'true' 'false' "File to output a .tar.bz2'd modules after the callbacks have run."
__register_config_option 'Output Settings' 'no-initrdmodules'	'false' 'false' 'Do not install any modules into the initramfs.'
__register_config_option 'Output Settings' 'no-kernel-sources' 'false' 'false' 'If there is a valid kerncache no checks will be made against a kernel source tree.'
__register_config_option 'Output Settings' 'log-override' 'true' 'false' '' # Hide

## Miscellaneous
__register_config_option 'Miscellaneous' 'help' 'false' 'false' '' # Hidden.

# Match $* against configuration registry and process...
parse_cmdline() {
	# Iterate over each registered config option and see if we have a match.
	local myRequest myName myTakesData myHasInversion myDataDefault myMatched=false

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
				config_set_key "${myName}" "${myRequest##*\=}"
				myMatched=true
			elif [ "${myTakesData}" = 'true!m' ]
			then
				config_set_key "${myName}" "$(config_get_key ${myName}) ${myRequest##*\=}"
				myMatched=true
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
			if [ "${myRequest:0:2}" = '::' ]
			then
				# Add to deptree
				__INTERNAL__CONFIG_PARSING_DEPTREE="${__INTERNAL__CONFIG_PARSING_DEPTREE} ${myRequest:2}"
				myMatched=true
			elif logicTrue ${myTakesData}
			then
				if [ "${myRequest}" = "--${myName}" ]
				then
					if [ -n "${myDataDefault}" ]
					then
						config_set_key "${myName}" "${myDataDefault}"
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
					config_set_key "${myName}" 'true'
					myMatched=true
				elif logicTrue ${myHasInversion} && [ "${myRequest}" = "--no-${myName}" ]
				then
					config_set_key "${myName}" 'false'
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

	local identifier data set_config
	while read i
	do
		# { identifier }{" := "}{quote}{data}{quote} or

		# Strip out inline comments
		i="${i/[ 	]\#*/}"

		if [[ "${i}" =~ '^\w+ := \".*\"$' ]]
		then
			identifier="${i% :=*}"
			data="${i#*:= \"}" # Remove up to first quote inclusive
			data="${data%\"}" # Remove end quote

			set_config="${set_config} ${identifier}"
			config_set_key "${identifier}" "${data}"
		# FIXME: profile deps
		elif [[ "${i}" =~ '^#' ]]
		then
			:
		else
			echo "# Invalid input: $i"
		fi
	done < "$1"

	[ -n "${set_config}" ] && echo "# Profile $1 set config vars:${set_config}"
}

config_profile_dump() {
	for (( n = 0 ; n < ${#__INTERNAL__OPTIONS__KEY[@]}; ++n )) ; do
		case "${__INTERNAL__OPTIONS__KEY[${n}]}" in
			profile|profile-dump)
				:
			;;
			*)
				echo "${__INTERNAL__OPTIONS__KEY[${n}]} := \"${__INTERNAL__OPTIONS__VALUE[${n}]}\""
			;;
		esac
	done
	exit 0
}
