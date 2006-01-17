# Many functions borrowed and modified from linux-info.eclass 

get_KV() {
	KERNEL_DIR="$1"
	[ ! -e "$1/Makefile" ] && die 'Kernel source tree invalid, no Makefile found!'

	# Configure the kernel

	KV_MAJOR=`grep ^VERSION\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
	KV_MINOR=`grep ^PATCHLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
	KV_PATCH=`grep ^SUBLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`

	KV_CODE="$(linux_kv_to_code ${KV_MAJOR} ${KV_MINOR} ${KV_PATCH})"
	KV_EXTRA=`grep ^EXTRAVERSION\ \= ${KERNEL_DIR}/Makefile | sed -e "s/EXTRAVERSION =//" -e "s/ //g" -e 's/\$([a-z]*)//gi'`

	# Local version
	local myLookup myList
	[[ -e "${KERNEL_DIR}/localversion" ]] && myList='localversion'
		
	[[ -n "$(ls ${KERNEL_DIR}/localversion*[^~] 2>/dev/null)" ]] && myList="${myList} $(ls ${KERNEL_DIR}/localversion*[^~])"

	for i in "${myList}"
	do
		[ "${i}" == '' ] && continue 
		KV_LOCAL="${KV_LOCAL}$(<${i})"
	done
		
	if [ -n "$(profile_get_key kbuild-output)" ]
	then
		KBUILD_OUTPUT="$(profile_get_key kbuild-output)"
	else
		KBUILD_OUTPUT=${KERNEL_DIR}
	fi

	if [ -f ${KBUILD_OUTPUT}/.config ]
	then
		myLookup="$(get_extconfig_var ${KBUILD_OUTPUT}/.config CONFIG_LOCALVERSION)"
		[ "${myLookup}" != '%lookup_fail%' ] && KV_LOCAL="${KV_LOCAL}${myLookup}"
	fi
	KV_LOCAL="${KV_LOCAL// /}"

	if [ "${KV_MINOR}" -lt '6' -a "${KV_MAJOR}" -eq '2' ]
	then
		die 'Kernel unsupported (2.6 or newer needed); exiting.'
	fi

	KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}${KV_LOCAL}"

	# Fixme; process CLI specified stuff
	profile_set_key kbuild-output ${KBUILD_OUTPUT}
}

genkernel_lookup_kernel() {
	get_KV $(profile_get_key kernel-tree)

	[ "$1" != 'silent' ] && NORMAL=${BOLD} print_info 1 "Kernel Tree: Linux Kernel ${BOLD}${KV_FULL}${NORMAL} for ${BOLD}${ARCH}${NORMAL}..."
	provide kernel_src_tree
}

get_extconfig_var() {
	# Check "$1" and return data of the token "$2=data"
	local myOut

	myOut="$(grep -m 1 $2 $1)"
	if [ "$?" -ne '0' ]
	then
		echo '%lookup_fail%'
		return
	fi

	# ... So it worked
	# Strip $2= out of the grep to get our result
	myOut="${myOut#$2=}"

	# Get rid of any double quotes
	echo "${myOut//\"/}"
}

kernel_is() {
	#[operator] [version2]
	linux_kv_cmp "${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}" $1 $2
}

linux_kv_cmp() {
	# [version1] [operator] [version2]

	local a=$1 b=$3 operator
	case ${2} in
	  lt) operator="-lt"; shift;;
	  gt) operator="-gt"; shift;;
	  le) operator="-le"; shift;;
	  ge) operator="-ge"; shift;;
	  eq) operator="-eq"; shift;;
	   *) operator="-eq";;
	esac

	# See if our version is non-numerical and if so convert
	[ "$a" != "${a/[. ]//}" ] && a="$(linux_kv_to_code ${a})"
	[ "$b" != "${b/[. ]//}" ] && b="$(linux_kv_to_code ${b})"

	[ ${a} "${operator}" ${b} ]
	return $?
}

# Arguments: {(a)(b)(c)}|{"a.b.c"}|{"a b c"}
# Output: Magnitude comparable integer
linux_kv_to_code() {
	local a b c in
	if [ "$#" -eq '1' ]
	then
		in=${1//./ }
		a=${in%% *}
		b=${in#* }
		b=${b%% *}
		c=${in##* }
		echo "$(( ($a << 16) + ($b << 8) + $c ))"
	else
		echo "$(( ($1 << 16) + ($2 << 8) + $3 ))"
	fi
}

linux_chkconfig_present() {
	# From linux-info eclass
	local RESULT
	RESULT="$(get_extconfig_var CONFIG_${1} ${KBUILD_OUTPUT}/.config)"
	[ "${RESULT}" = "m" -o "${RESULT}" = "y" ] && return 0 || return 1
}

linux_chkconfig_module() {
	# From linux-info eclass
	local RESULT
	RESULT="$(get_extconfig_var CONFIG_${1} ${KBUILD_OUTPUT}/.config)"
	[ "${RESULT}" = "m" ] && return 0 || return 1
}

linux_chkconfig_builtin() {
	# From linux-info eclass
	local RESULT
	RESULT="$(get_extconfig_var CONFIG_${1} ${KBUILD_OUTPUT}/.config)"
	[ "${RESULT}" = "y" ] && return 0 || return 1
}

linux_chkconfig_string() {
	# From linux-info eclass
	get_extconfig_var "CONFIG_${1}" "${KBUILD_OUTPUT}/.config"
}

check_modules_supported() {
	[ linux_chkconfig_builtin "MODULES" ] && return 0 || return 1
}

check_asm_link_ok() {
	workingdir=${PWD}
	if [ -e "${KBUILD_OUTPUT}/include/asm" ]
	then
		cd ${KBUILD_OUTPUT}/include
		if [ -h "asm" ]
		then 
			asmlink="$(readlink -f asm)"
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

kernel_config_set_string() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s|#\? \?CONFIG_${1} is.*|CONFIG_${1}=\"${2}\"|g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s|CONFIG_${1}=.*|CONFIG_${1}=\"${2}\"|g"
}
kernel_config_set_builtin() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=m/CONFIG_${1}=y/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=y/g"
}

kernel_config_set_module() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=y/CONFIG_${1}=m/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=m/g"
}

kernel_config_unset() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=y/# CONFIG_${1} is not set/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=m/# CONFIG_${1} is not set/g"
}


determine_config_file() {
	#echo "$(profile_get_key kernel-config)"
	#echo "/etc/kernels/kernel-config-${ARCH}-${KV_FULL}"
	#echo "${CONFIG_DIR}/kernel-config-${KV_FULL}"
	#echo "${DEFAULT_KERNEL_CONFIG}"
	#echo "${CONFIG_DIR}/kernel-config-${KV_MAJOR}.${KV_MINOR}"
	#echo "${CONFIG_DIR}/kernel-config"
    
	if [ -n "$(profile_get_key kernel-config)" ]
    then
        KERNEL_CONFIG="$(profile_get_key kernel-config)"
		
    elif [ -f "/etc/kernels/kernel-config-${ARCH}-${KV_FULL}" ]
    then
        KERNEL_CONFIG="/etc/kernels/kernel-config-${ARCH}-${KV_FULL}"
    elif [ -f "${CONFIG_DIR}/kernel-config-${KV_FULL}" ]
    then
        KERNEL_CONFIG="${CONFIG_DIR}/kernel-config-${KV_FULL}"
	elif [ "${DEFAULT_KERNEL_CONFIG}" != "" -a -f "${DEFAULT_KERNEL_CONFIG}" ]
    then
        KERNEL_CONFIG="${DEFAULT_KERNEL_CONFIG}"
    elif [ -f "${CONFIG_DIR}/kernel-config-${KV_MAJOR}.${KV_MINOR}" ]
    then
        KERNEL_CONFIG="${CONFIG_DIR}/kernel-config-${KV_MAJOR}.${KV_MINOR}"
    elif [ -f "${CONFIG_DIR}/kernel-config" ]
    then
        KERNEL_CONFIG="${CONFIG_DIR}/kernel-config"
    else
        die 'Error: No kernel .config specified, or file not found!'
    fi
}

kbuild_enabled() {
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then 
		return 0
	else
		return 1
	fi
}

setup_kernel_args() {
	# Override the default arch being built
	[ -n "$(profile_get_key arch-override)" ] && ARGS="${ARGS} ARCH=$(profile_get_key arch-override)"

	# Turn off KBUILD_OUTPUT if kbuild_output is the same as the kernel tree or die if arch=um or xen0 or xenU
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		if [ -n "$(profile_get_key kbuild-output)" ]
		then
			ARGS="${ARGS} KBUILD_OUTPUT=$(profile_get_key kbuild-output)"
			mkdir -p $(profile_get_key kbuild-output)
		fi
	elif [ "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		if [    "$(profile_get_key arch-override)" == "um" -o "$(profile_get_key arch-override)" == "xen0" \
			-o "$(profile_get_key arch-override)" == "xenU" ]
		then
			die "Compiling for ARCH=$(profile_get_key arch-override) requires kbuild_output to differ from the kernel-tree"
		fi
	fi

	# Kernel cross compiling support
	if [ -n "$(profile_get_key cross-compile)" ]
	then
		ARGS="${ARGS} CROSS_COMPILE=$(profile_get_key cross-compile)"
	else
		[ -n "$(profile_get_key kernel-cross-compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(profile_get_key kernel-cross-compile)"
	fi


	# Set the destination path for the kernel
	if [ -n "$(profile_get_key install-path)" ]
	then
		ARGS="${ARGS} INSTALL_PATH=$(profile_get_key install-path)"
		mkdir -p $(profile_get_key install-path) || die 'Failed to create install path!'
	fi

	# Set the destination path for the modules
	if [ -n "$(profile_get_key install-mod-path)" ]
	then
		ARGS="${ARGS} INSTALL_MOD_PATH=$(profile_get_key install-mod-path)"
		mkdir -p $(profile_get_key install-mod-path) || die 'Failed to create module install path!'
	fi
}

