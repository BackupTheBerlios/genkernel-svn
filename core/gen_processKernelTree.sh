# Many functions borrowed and modified from linux-info.eclass 

get_KV() {
	# borrowed and twisted from linux-info.eclass
	
	# There are also a couple of variables which are set by this, and shouldn't be
	# set by hand. These are as follows:
	#
	# Env Var       Option      Description
	# KV_FULL       <string>    The full kernel version. ie: 2.6.9-gentoo-johnm-r1
	# KV_MAJOR      <integer>   The kernel major version. ie: 2
	# KV_MINOR      <integer>   The kernel minor version. ie: 6
	# KV_PATCH      <integer>   The kernel patch version. ie: 9
	# KV_EXTRA      <string>    The kernel EXTRAVERSION. ie: -gentoo
	# KV_LOCAL      <string>    The kernel LOCALVERSION concatenation. ie: -johnm
	# KV_DIR        <string>    The kernel source directory, will be null if
	#                   KERNEL_DIR is invalid.
	# KV_OUT_DIR        <string>    The kernel object directory. will be KV_DIR unless
	#                   koutput is used. This should be used for referencing
	#                   .config.

	local kbuild_output
		
	# no need to execute this twice assuming KV_FULL is populated.
	# we can force by unsetting KV_FULL
    
	[ -n "${KV_FULL}" ] && return 0

    # if we dont know KV_FULL, then we need too.
    # make sure KV_DIR isnt set since we need to work it out via KERNEL_DIR
    unset KV_DIR
	KERNEL_DIR="${KERNEL_DIR:-$(config_get_key kernel-tree)}"  # Should this be settable via env variable as well?
	[ -h "${KERNEL_DIR}" ] && KV_DIR="$(readlink -f ${KERNEL_DIR})"
	[ -d "${KERNEL_DIR}" ] && KV_DIR="${KERNEL_DIR}"

	if [ -z "${KV_DIR}" ]
	then
		die "need to have KERNEL_DIR set"
	fi
	
	if [ "$(config_get_key debuglevel)" -gt "1" ]
	then
		print_info 1 '>> Found kernel source directory:'
		print_info 1 ">>      ${KV_DIR}"
	fi
	
	if [ ! -s "${KV_DIR}/Makefile" ]
	then
		die "Could not find a Makefile in the kernel source directory."
	fi
	
	# genkernel setup the output dir
	[ -n "$(config_get_key kbuild-output)" ] && OUTPUT_DIR=$(config_get_key kbuild-output)
	
	# OK so now we know our sources directory, but they might be using
	# KBUILD_OUTPUT, and we need this for .config and localversions-*
	# so we better find it eh?
	# do we pass KBUILD_OUTPUT on the CLI?
	
	[ -n "$(config_get_key kbuild-output)" ] && OUTPUT_DIR=$(config_get_key kbuild-output)
	OUTPUT_DIR="${OUTPUT_DIR:-${KBUILD_OUTPUT}}"

    # parse ${KV_DIR}/Makefile to get the Kernel information
    KV_MAJOR="$(getfilevar VERSION ${KV_DIR}/Makefile)"
    KV_MINOR="$(getfilevar PATCHLEVEL ${KV_DIR}/Makefile)"
    KV_PATCH="$(getfilevar SUBLEVEL ${KV_DIR}/Makefile)"
    KV_EXTRA="$(getfilevar EXTRAVERSION ${KV_DIR}/Makefile)"
	
	if [ -z "${KV_MAJOR}" -o -z "${KV_MINOR}" -o -z "${KV_PATCH}" ]
	then
		die "Could not detect kernel version. Is ${KERNEL_DIR} a complete set of linux sources?"
	fi

	[ -h "${OUTPUT_DIR}" ] && KV_OUT_DIR="$(readlink -f ${OUTPUT_DIR})"
    [ -d "${OUTPUT_DIR}" ] && KV_OUT_DIR="${OUTPUT_DIR}"

	if [ "$(config_get_key debuglevel)" -gt "1" ]
	then
		if [ -n "${KV_OUT_DIR}" ];
		then
			print_info 1 '>> Found kernel object directory:'
			print_info 1 ">>      ${KV_OUT_DIR}"
		fi
	fi
    
	# and if we STILL haven't got KV_OUT_DIR, then we better just set it to KV_DIR
    KV_OUT_DIR="${KV_OUT_DIR:-${KV_DIR}}"

	KV_LOCAL="$(get_localversion ${KV_OUT_DIR})"

    KV_LOCAL="${KV_LOCAL}$(get_localversion ${KV_OUT_DIR})"
    KV_LOCAL="${KV_LOCAL}$(linux_chkconfig_string LOCALVERSION)"
    KV_LOCAL="${KV_LOCAL//\"/}"
    
	# And we should set KV_FULL to the full expanded version
    KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}${KV_LOCAL}"

	if [ "$(config_get_key debuglevel)" -gt "1" ]
	then
		print_info 1 '>> Found kernel version:'
		print_info 1 ">>     ${KV_FULL}"
	fi

	config_set_key kernel-tree ${KERNEL_DIR}
	config_set_key kbuild-output ${KV_OUT_DIR}
}
	


genkernel_lookup_kernel() {
	local myTree
	get_KV;
	
	# Decide whether to keep config or update it
	# If the tree looks good provide it...

	[ "$1" != 'silent' ] && NORMAL=${BOLD} print_info 1 "Kernel Tree: Linux Kernel ${BOLD}${KV_FULL}${NORMAL} for ${BOLD}${ARCH}${NORMAL}..."
	provide kernel_src_tree
}





# Versioning Functions
# ---------------------------------------

# kernel_is returns true when the version is the same as the passed version
#
# For Example where KV = 2.6.9
# kernel_is 2 4     returns false
# kernel_is 2       returns true
# kernel_is 2 6     returns true
# kernel_is 2 6 8   returns false
# kernel_is 2 6 9   returns true
#
# got the jist yet?

kernel_is() {
	# function borrowed from linux-info.eclass in gentoo.
	local operator test value x=0 y=0 z=0
	get_KV;

    case ${1} in
      lt) operator="-lt"; shift;;
      gt) operator="-gt"; shift;;
      le) operator="-le"; shift;;
      ge) operator="-ge"; shift;;
      eq) operator="-eq"; shift;;
       *) operator="-eq";;
    esac

    for x in ${@}; do
        for((y=0; y<$((3 - ${#x})); y++)); do value="${value}0"; done
        value="${value}${x}"
        z=$((${z} + 1))

        case ${z} in
          1) for((y=0; y<$((3 - ${#KV_MAJOR})); y++)); do test="${test}0"; done;
             test="${test}${KV_MAJOR}";;
          2) for((y=0; y<$((3 - ${#KV_MINOR})); y++)); do test="${test}0"; done;
             test="${test}${KV_MINOR}";;
          3) for((y=0; y<$((3 - ${#KV_PATCH})); y++)); do test="${test}0"; done;
             test="${test}${KV_PATCH}";;
          *) die "Error in kernel_is(): Too many parameters.";;
        esac
    done
	
    [ ${test} ${operator} ${value} ] && return 0 || return 1
}

get_localversion() {
	# function borrowed from linux-info.eclass in gentoo.
    local lv_list i x

    # ignore files with ~ in it.
    for i in $(ls ${1}/localversion* 2>/dev/null); do
        [[ -n ${i//*~*} ]] && lv_list="${lv_list} ${i}"
    done

    for i in ${lv_list}; do
        x="${x}$(<${i})"
    done
    x=${x/ /}
    echo ${x}
}


kernel_is_2_4() {
    kernel_is 2 4
}

kernel_is_2_6() {
	kernel_is 2 6 || kernel_is 2 5
}
		



# File Functions
# ---------------------------------------

# getfilevar accepts 2 vars as follows:
# getfilevar <VARIABLE> <CONFIGFILE>


getfilevar() {
	# idea borrowed from linux-info eclass
	local  ERROR workingdir basefname basedname myARCH="${ARCH}"
    ERROR=0

	[ -z "${1}" ] && ERROR=1
	[ ! -f "${2}" ] && ERROR=1

	if [ "${ERROR}" = 1 ]
	then
		die "getfilevar requires 2 variables, eg getfilevar <VARIABLE> <VALID_CONFIGFILE>"
	else
		workingdir=${PWD}
        basefname=$(basename ${2})
        basedname=$(dirname ${2})
        unset ARCH

        cd ${basedname}
		echo -e "include ${basefname}\ne:\n\t@echo \$(${1})" |\
		make -s -f - e 2>/dev/null	
        cd ${workingdir}

        ARCH=${myARCH}
	fi
}


linux_chkconfig_present() {
# borrowed from linux-info eclass
local   RESULT
    RESULT="$(getfilevar CONFIG_${1} ${KV_OUT_DIR}/.config)"
    [ "${RESULT}" = "m" -o "${RESULT}" = "y" ] && return 0 || return 1
}

linux_chkconfig_module() {
# borrowed from linux-info eclass
local   RESULT
    RESULT="$(getfilevar CONFIG_${1} ${KV_OUT_DIR}/.config)"
    [ "${RESULT}" = "m" ] && return 0 || return 1
}

linux_chkconfig_builtin() {
# borrowed from linux-info eclass
local   RESULT
    RESULT="$(getfilevar CONFIG_${1} ${KV_OUT_DIR}/.config)"
    [ "${RESULT}" = "y" ] && return 0 || return 1
}

linux_chkconfig_string() {
# borrowed from linux-info eclass
    getfilevar "CONFIG_${1}" "${KV_OUT_DIR}/.config"
}

kernel_configured() {
    # if we haven't determined the version yet, we need too.
    get_KV;

	[ ! -f "${KV_OUT_DIR}/include/linux/version.h" ] && return 0 || return 1
}

check_modules_supported() {
    # if we haven't determined the version yet, we need too.
    get_KV;
	[ linux_chkconfig_builtin "MODULES" ] && return 0 || return 1
}

check_asm_link_ok() {
	workingdir=${PWD}
	cd ${KV_OUT_DIR}/include
	if [ -e "asm" ]
	then
		if [ -h "asm" ]
		then 
			asmlink="$(readlink -f asm)"
			echo $(basename ${asmlink})
			echo asm-${1}
			if [ $(basename ${asmlink}) == "asm-${1}" ]
			then
				cd ${workingdir}
				return 0
			else
				cd ${workingdir}
				return 1
			fi
		fi	
	else
		cd ${workingdir}
		# No link setup yet which is ok...
		return 0
	fi
}
	
config_set_builtin() {
    # if we haven't determined the version yet, we need too.
    get_KV;
	sed -i ${KV_OUT_DIR}/.config -e "s/CONFIG_${1}=m/CONFIG_${1}=y/g"
	sed -i ${KV_OUT_DIR}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=y/g"
	echo "CONFIG_${1}: Should be a builtin"
	grep "CONFIG_${1}=" ${KV_OUT_DIR}/.config
	grep "CONFIG_${1} is" ${KV_OUT_DIR}/.config
}

config_set_module() {
    # if we haven't determined the version yet, we need too.
    get_KV;
	sed -i ${KV_OUT_DIR}/.config -e "s/CONFIG_${1}=y/CONFIG_${1}=m/g"
	sed -i ${KV_OUT_DIR}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=m/g"
	echo "CONFIG_${1}: Should be a module"
	grep "CONFIG_${1}=" ${KV_OUT_DIR}/.config
	grep "CONFIG_${1} is" ${KV_OUT_DIR}/.config
}

config_unset() {
    # if we haven't determined the version yet, we need too.
    get_KV;
	sed -i ${KV_OUT_DIR}/.config -e "s/CONFIG_${1}=y/# CONFIG_${1} is not set/g"
	sed -i ${KV_OUT_DIR}/.config -e "s/CONFIG_${1}=m/# CONFIG_${1} is not set/g"
	echo "CONFIG_${1}: Should be not set"
	grep "CONFIG_${1}=" ${KV_OUT_DIR}/.config
	grep "CONFIG_${1} is" ${KV_OUT_DIR}/.config
}
