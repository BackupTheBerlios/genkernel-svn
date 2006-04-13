#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Functions library for GMI scripts, generic functions
#

### TODO: splash stuff...
#
#
splash() {
	return 0
}

# FS loaders can register env variables that will
# be passed to the running system after they return
#
# ${1} Variable to set (eg 'CDBOOT=1')
#
gmi_register_env() {
        echo "export ${1}" >> /etc/profile.fsloaders
}


# Checks if an option is set
#
# ${1} Variable to test
#
gmi_is_set() {
        if [ "${1}" = "NONE" ]; then
                return 1
        elif [ -z "${1}" ]; then
                return 1
        else
                return 0
        fi
}


# Returns and increments a counter on each calls (useful for creating unique
# directories and keep an order relation)
#
# (No parameters)
#
gmi_counter() {
	if [ ! -r /tmp/counter ]
	then
		echo "0" > /tmp/counter
	fi
	cat /tmp/counter
	echo $(( `cat /tmp/counter` + 1 )) > /tmp/counter
}


# Creates a non-union mountpoint directory
#
# (No parameters)
#
gmi_mkmntpoint() {
	local dir=${MNTOTHER}/mountpoint.`gmi_counter`
	mkdir ${dir}
	echo ${dir}
}

# Creates a will-be-unionized in / mountpoint directory
#
# (No parameters)
#
gmi_mkumntpoint() {
	local dir=${UNIONS}/mountpoint.`gmi_counter`
	mkdir ${dir}
	echo ${dir}
}


# Tests if ${1} is in ${2}, a list with ${3} separators
# if the separator is not set, assume it is ','
#
# (this default is because it is frequently used for parsing 
# the fsloaders options, which are comma separated)
#
# ${1} What to look for in..
# ${2} ...this list...
# ${3} ...with these separatros (',' if not set)
#
gmi_has() {
        local separator="${3}"
        [ -z "${separator}" ] && separator=','
        local list="${separator}${2}${separator}"

        echo "${list}" | grep "${separator}${1}${separator}" > /dev/null

        return $?
}


# Echo a good message
#
# ${1} Message
#
gmi_good_msg() {
	msg_string=$1
	msg_string="${msg_string:-...}"
	echo -e "${GOOD}>>${NORMAL}${BOLD} ${msg_string} ${NORMAL}"
}


# Echo a bad message
#
# ${1} Message
#
gmi_bad_msg() {
	msg_string=$1
	msg_string="${msg_string:-...}"
	echo -e "${BAD}!!${NORMAL}${BOLD} ${msg_string} ${NORMAL}"
}


# Echo a warning message
#
# ${1} Message
#
gmi_warn_msg() {
	msg_string=$1
	msg_string="${msg_string:-...}"
	echo -e "${WARN}**${NORMAL}${BOLD} ${msg_string} ${NORMAL}"
}


# Echo a debug message, will print only if $DEBUG is set
#
# ${1} Message
#
gmi_dbg_msg() {
        [ -n "${DEBUG}" ] && echo -e "${BOLD}dbg${NORMAL} $1"
}

# Returns info on the last command's return value, if $DEBUG is set
#
# (No parameters)
#
gmi_dbg_res() {
	if [ "$?" != '0' ]; then
		gmi_dbg_msg 'error'
	else
		gmi_dbg_msg 'ok'
	fi
}


# Prints a message if a given value is not 'true'
#
# ${1} Value
# ${2} Message
#
gmi_assert() {
        if [ "${1}" != "0" ]
	then
		gmi_bad_msg "${2}"
		return 1
        else
		return 0
	fi
}


# Start a shell
#
# (No parameters)
#
gmi_shell(){
	if [ -n "$DEBUG" ]
	then
		gmi_good_msg 'Starting debug shell as requested by "debug" option.'
		gmi_good_msg 'Type "exit" to continue with normal bootup.'
	fi
	cd /

	# Fix for UML
	if gmi_is_uml_sys
	then
		openvt 0 /bin/ash
	else
		openvt 1 /bin/ash
	fi
}

# Parse the kernel command line and set variables accordingly
#
# (No parameters)
#
gmi_parse_cmdline() {
	for x in ${CMDLINE}
	do
		case "${x}" in
			root\=*)
				REAL_ROOT=${x#root=}
				# post processing after the case switch
				;;
			real_root\=*)
				REAL_ROOT=${x#real_root=}
				# post processing after the case switch
				;;
			real_init\=*)
				INIT=${x#real_init=}
				;;
			init\=*)
				INIT=${x#init=}
				;;

			# force unionfs usage 
			# (else automatically determined by the real_root=xx;yy)
			unionfs)
				FORCED_UNIONFS='yes'
				;;

			# post-unpacking files
			unpack\=*)
				UNPACK=${x#unpack=}
				;;

			# Debug Options
			debug)
				DEBUG='yes'
				;;

			# Scan delay options 
			scandelay)
				SCANDELAY=10
				;;
			scandelay\=*)
				SCANDELAY=${x#scandelay=}
				;;

			# Module no-loads
			doload\=*)
				MDOLIST=${x#doload=}
				MDOLIST="`echo ${MDOLIST} | sed -e \"s/,/ /g\"`"
				;;
			noload\=*)
				MLIST=${x#noload=}
				MLIST="`echo ${MLIST} | sed -e \"s/,/ /g\"`"
				export MLIST
				;;
			nodetect)
				NODETECT=1
				;;
		
			CONSOLE\=*)
				CONSOLE=${x#console=}
				exec >${CONSOLE} <${CONSOLE} 2>&1
				;;


			# NETWORKING
			ip\=*)
				IP=${x#ip=}
				;;
			nameserver\=*)
				NAMESERVER=${x#nameserver=}
				;;
		esac
	done
}


# Unpacks a file to a directory
#
# ${1} File path 
# ${2} Directory
#
gmi_unpack() {
	local file="${1}"
	local out="${2}"
	local tarflags

	[ ! -r "${file}" ] && return 1
	[ ! -w "${out}" ] && return 1

	### TODO : perhaps we could also unpack loop files?
	case "${file}" in
		*.tar.bz2|*.tbz2)
                        tarflags='j'
			;;
		*.tar.gz|*.tgz)
			tarflags='z'
			;;
		*.tar)
			tarflags=''
			;;
		*)
			gmi_dbg_msg "Unrecognized filetype to unpack: ${file}!"
			return 1
			;;
	esac

	tar -${tarflags}xpf ${file} -C${out}
	if [ "$?" != "0" ]
	then
		gmi_dbg_msg "Problem when unpacking ${file} to ${out}"
		return 1
	fi
}
