#!/bin/bash

gen_die() {
	echo "${BAD}Error${NORMAL}: $1"
	exit 1
}

set_color() {
    if logicTrue $(config_get_key usecolor)
    then
        GOOD=$'\e[32;01m'
        WARN=$'\e[33;01m'
        BAD=$'\e[31;01m'
        NORMAL=$'\e[0m'
        BOLD=$'\e[0;01m'
        UNDER=$'\e[4m'
    else
        echo '[ Turning color off ]'
        GOOD=''
        WARN=''
        BAD=''
        NORMAL=''
        BOLD=''
        UNDER=''
    fi
}

dump_debugcache() {
	TODEBUGCACHE=false
	echo "${DEBUGCACHE}" >> ${DEBUGFILE}
}

trap_cleanup(){
    # Call exit code of 1 for failure
    cleanup
    exit 1
}

cleanup(){
    if [ -n "$TEMP" -a -d "$TEMP" ]; then
    rm -rf "$TEMP"
    fi

    if isTrue ${POSTCLEAR}
    then
        echo
        print_info 1 'RUNNING FINAL CACHE/TMP CLEANUP'
        print_info 1 "CACHE_DIR: ${CACHE_DIR}"
        CLEAR_CACHE_DIR='yes'
        setup_cache_dir
        echo
        print_info 1 "CACHE_CPIO_DIR: ${CACHE_CPIO_DIR}"
        CLEAR_CPIO_CACHE='yes'
        clear_cpio_dir
        echo
        print_info 1 "TMPDIR: ${TMPDIR}"
        clear_tmpdir
    fi
}
print_header() {
	NORMAL=${GOOD} print_info 1 "Gentoo Linux Genkernel; Version ${GK_V}${NORMAL}"
	print_info 1 "Running with options: ${Options}"
	echo
}
# print_info(debuglevel, print [, newline [, prefixline [, forcefile ] ] ])
print_info() {
	local NEWLINE=1
	local FORCEFILE=0
	local PREFIXLINE=1
	local SCRPRINT=0
	local STR=''

	# Not enough args
	if [ "$#" -lt '2' ] ; then return 1; fi

	# Check if we want a newline since the param is specified
	if [ "$#" -gt '2' ]
	then
		if logicTrue "$3"
		then
			NEWLINE='1';
		else
			NEWLINE='0';
		fi
	fi

	# Check prefix
	if [ "$#" -gt '3' ]
	then
		if logicTrue "$4"
		then
			PREFIXLINE='1'
		else
			PREFIXLINE='0'
		fi
	fi

	# IF 5 OR MORE ARGS, CHECK IF WE WANT TO FORCE OUTPUT TO DEBUG
	# FILE EVEN IF IT DOESN'T MEET THE MINIMUM DEBUG REQS
	if [ "$#" -gt '4' ]
	then
		if logicTrue "$5"
		then
			FORCEFILE='1'
		else
			FORCEFILE='0'
		fi
	fi

	# PRINT TO SCREEN ONLY IF PASSED DEBUGLEVEL IS HIGHER THAN
	# OR EQUAL TO SET DEBUG LEVEL
	if [ "$1" -lt "${DEBUGLEVEL}" -o "$1" -eq "${DEBUGLEVEL}" ]
	then
		SCRPRINT='1'
	fi

	# RETURN IF NOT OUTPUTTING ANYWHERE
	if [ "${SCRPRINT}" != '1' -a "${FORCEFILE}" != '1' ]
	then
		return 0
	fi

	# STRUCTURE DATA TO BE OUTPUT TO SCREEN, AND OUTPUT IT
	if [ "${SCRPRINT}" -eq '1' ]
	then
		if [ "${PREFIXLINE}" = '1' ]
		then
			STR="${GOOD}*${NORMAL} ${2}"
		else
			STR="${2}"
		fi

		if [ "${NEWLINE}" = '0' ]
		then
			echo -ne "${STR}"
		else
			echo "${STR}"
		fi
	fi

	# STRUCTURE DATA TO BE OUTPUT TO FILE, AND OUTPUT IT
	if [ "${SCRPRINT}" -eq '1' -o "${FORCEFILE}" -eq '1' ]
	then
		STRR=${2//${WARN}/}
		STRR=${STRR//${BAD}/}
		STRR=${STRR//${BOLD}/}
		STRR=${STRR//${NORMAL}/}

		if [ "${PREFIXLINE}" = '1' ]
		then
			STR="* ${STRR}"
		else
			STR="${STRR}"
		fi

		if [ "${NEWLINE}" = '0' ]
		then
			if logicTrue "${TODEBUGCACHE}" ; then
				DEBUGCACHE="${DEBUGCACHE}${STR}"
			else
				echo -ne "${STR}" >> ${DEBUGFILE}
			fi	
		else
			if logicTrue "${TODEBUGCACHE}" ; then
				DEBUGCACHE="${DEBUGCACHE}${STR}"$'\n'
			else
				echo "${STR}" >> ${DEBUGFILE}
			fi
		fi
	fi

	return 0
}

print_error()
{
	GOOD=${BAD} print_info "$@"
}

print_warning()
{
	GOOD=${WARN} print_info "$@"
}

# var_replace(var_name, var_value, string)
# $1 = variable name
# $2 = variable value
# $3 = string

var_replace()
{
  # Escape '\' and '.' in $2 to make it safe to use
  # in the later sed expression
  local SAFE_VAR
  SAFE_VAR=`echo "${2}" | sed -e 's/\([\/\.]\)/\\\\\\1/g'`
  
  echo "${3}" | sed -e "s/%%${1}%%/${SAFE_VAR}/g" -
}

arch_replace() {
  var_replace "ARCH" "${ARCH}" "${1}"
}

kv_replace() {
  var_replace "KV" "${KV}" "${1}"
}

cache_replace() {
  var_replace "CACHE" "${CACHE_DIR}" "${1}"
}

clear_log() {
    if [ -f "${DEBUGFILE}" ]
    then
	(echo > "${DEBUGFILE}") 2>/dev/null || gen_die "Could not write to ${DEBUGFILE}."
    fi   
}

gen_die_debugged() {
	dump_debugcache

	if [ "$#" -gt '0' ]
	then
		print_error 1 "ERROR: ${1}"
	fi
	echo
	print_info 1 "-- Grepping log... --"
	echo

	if logicTrue ${USECOLOR}
	then
		GREP_COLOR='1' grep -B5 -E --colour=always "([Ww][Aa][Rr][Nn][Ii][Nn][Gg]|[Ee][Rr][Rr][Oo][Rr][ :,!]|[Ff][Aa][Ii][Ll][Ee]?[Dd]?)" ${DEBUGFILE}
	else
		grep -B5 -E "([Ww][Aa][Rr][Nn][Ii][Nn][Gg]|[Ee][Rr][Rr][Oo][Rr][ :,!]|[Ff][Aa][Ii][Ll][Ee]?[Dd]?)" ${DEBUGFILE}
	fi
	echo
	print_info 1 "-- End log... --"
	echo
	print_info 1 "Please consult ${DEBUGFILE} for more information and any"
	print_info 1 "errors that were reported above."
	echo
	print_info 1 "Report any genkernel bugs to bugs.gentoo.org and"
	print_info 1 "assign your bug to genkernel@gentoo.org. Please include"
	print_info 1 "as much information as you can in your bug report; attaching"
	print_info 1 "${DEBUGFILE} so that your issue can be dealt with effectively."
	print_info 1 ''
	print_info 1 'Please do *not* report compilation failures as genkernel bugs!'
	print_info 1 ''

	# Cleanup temp dirs and caches if requested
	cleanup
  	exit 1
}

has_loop() {
	dmesg | egrep -q '^loop:'
	if [ -e '/dev/loop0' -o -e '/dev/loop/0' -a ${PIPESTATUS[1]} ]
	then
		# We found devfs or standard dev loop device, assume
		# loop is compiled into the kernel or the module is loaded
		return 0
	else
		return 1
	fi
}

isBootRO()
{
	for mo in `grep ' /boot ' /proc/mounts | cut -d ' ' -f 4 | sed -e 's/,/ /'`
	do
		if [ "x${mo}x" == "xrox" ]
		then
			return 0
		fi
	done
	return 1
}

setup_cache_dir()
{
	[ ! -d "${CACHE_DIR}" ] && mkdir -p "${CACHE_DIR}"

	if [ "${CLEAR_CACHE_DIR}" == 'yes' ]
	then
		print_info 1 "Clearing cache dir contents from ${CACHE_DIR}"
		CACHE_DIR_CONTENTS=`ls ${CACHE_DIR}|grep -v CVS|grep -v cpio|grep -v README`

		for i in ${CACHE_DIR_CONTENTS}
		do
			print_info 1 "	 >> removing ${i}"
			rm ${CACHE_DIR}/${i}
		done
	fi
}

clear_tmpdir()
{
	if ! logicTrue ${CMD_NOINSTALL}
	then
		TMPDIR_CONTENTS=`ls ${TMPDIR}`
		print_info 1 "Removing tmp dir contents"
		for i in ${TMPDIR_CONTENTS}
		do
			print_info 1 "	 >> Removing ${i}"
			rm ${TMPDIR}/${i}
		done
	fi
}

genkernel_determine_arch() {
	local myArch=$(config_get_key arch-override)
	if [ "${myArch}" != '' ]
	then
		ARCH=${myArch}
	else
		ARCH=$(uname -m)
		case "${ARCH}" in
			i?86)
				ARCH='x86'
			;;
			*)
			;;
		esac
	fi

	ARCH_CONFIG="${GK_SHARE}/${ARCH}/config.sh"
	[ -f "${ARCH_CONFIG}" ] || gen_die "${ARCH} not yet supported by genkernel. Please add the arch-specific config file, ${ARCH_CONFIG}"
}

# has test list
# Return true if list contains test
has() {
	# From eselect

	local test=${1} item
	shift
	for item in $@; do
		[[ ${item} == ${test} ]] && return 0
	done
	return 1
}

logicTrue() {
	[ "$*" = 'true' ] && return 0
	return 1
}

## Compilation functions

compile_generic() {
	local RET myAction

	[ "$#" -lt '2' ] &&
		gen_die 'compile_generic(): improper usage!'

	myAction="$1"
	shift

	if [ "${myAction}" = 'kernel' ] || [ "${myAction}" = 'runtask' ]
	then
		export CROSS_COMPILE="$(config_get_key kernel-cross-compile)"
#	elif [ "${2}" = 'utils' ]
#	then
#		export_utils_args
#		MAKE=${UTILS_MAKE}
	fi
#	case "$2" in
#		kernel) ARGS="`compile_kernel_args`" ;;
#		utils) ARGS="`compile_utils_args`" ;;
#		*) ARGS="" ;; # includes runtask
#	esac

	if [ "${myAction}" == 'runtask' ]
	then
		print_info 2 "COMMAND: ${MAKE} ${MAKEOPTS/-j?/j1} $@" 1 0 1
		make -s "$@"
		RET=$?
	elif [ "${DEBUGLEVEL}" -gt "1" ]
	then
		# Output to stdout and debugfile
		print_info 2 "COMMAND: ${MAKE} ${MAKEOPTS} $@" 1 0 1
		make $(config_get_key makeopts) "$@" 2>&1 | tee -a ${DEBUGFILE}
		RET=${PIPESTATUS[0]}
	else
		# Output to debugfile only
		print_info 2 "COMMAND: ${MAKE} ${MAKEOPTS} $@" 1 0 1
		make $(config_get_key makeopts) "$@" >> ${DEBUGFILE} 2>&1
		RET=$?
	fi
	[ "${RET}" -ne '0' ] && gen_die "Failed to compile the \"${1}\" target..."
}
