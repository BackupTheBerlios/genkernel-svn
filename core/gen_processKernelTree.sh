# Many functions borrowed and modified from linux-info.eclass 

get_KV() {
	KERNEL_DIR="$1"
	[ ! -e "$1/Makefile" ] && die 'Kernel source tree invalid, no Makefile found!'

	if [ "$(config_get_key no-kernel-sources)" = 'true' ]
	then
		die '--no-kernel-sources requires a valid --kerncache!'
	else
		# Configure the kernel

		KV_MAJOR=`grep ^VERSION\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		KV_MINOR=`grep ^PATCHLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		KV_PATCH=`grep ^SUBLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		KV_EXTRA=`grep ^EXTRAVERSION\ \= ${KERNEL_DIR}/Makefile | sed -e "s/EXTRAVERSION =//" -e "s/ //g" -e 's/\$([a-z]*)//gi'`

		# Local version
		local myLookup myList=''
		[[ -e "${KERNEL_DIR}/localversion" ]] && myList='localversion'
		[[ "${KERNEL_DIR}/localversion*[^~]" != "${KERNEL_DIR}/localversion\*[^~]" ]] && myList="${myList} ${KERNEL_DIR}/localversion*[^~]"

		for i in "${myList}"
		do
			KV_LOCAL="${KV_LOCAL}$(<${i})"
		done
		
		if [ -n "$(config_get_key kbuild-output)" ]
		then
			KBUILD_OUTPUT="$(config_get_key kbuild-output)"
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
	fi

	KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}${KV_LOCAL}"

	# Fixme; process CLI specified stuff
	config_set_key kbuild-output ${KBUILD_OUTPUT}
}

genkernel_lookup_kernel() {
	get_KV $(config_get_key kernel-tree)

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
	
config_set_builtin() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=m/CONFIG_${1}=y/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=y/g"
}

config_set_module() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=y/CONFIG_${1}=m/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=m/g"
}

config_unset() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=y/# CONFIG_${1} is not set/g"
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=m/# CONFIG_${1} is not set/g"
}
