# Output: binpackage { / -> "busybox" }
# Placement: TBD

busybox_compile::()
{
	local	BUSYBOX_SRCTAR="${SRCPKG_DIR}/busybox-${BUSYBOX_VER}.tar.bz2" BUSYBOX_DIR="busybox-${BUSYBOX_VER}" \
		BUSYBOX_CONFIG
	[ -f "${BUSYBOX_SRCTAR}" ] || die "Could not find busybox source tarball: ${BUSYBOX_SRCTAR}!"

	if [ -n "$(profile_get_key busybox-config)" ]
	then
		BUSYBOX_CONFIG="$(profile_get_key busybox-config)"
	elif [ -f "${TEMP}/busybox-custom-${BUSYBOX_VER}.config" ]
	then
		BUSYBOX_CONFIG="${TEMP}/busybox-custom-${BUSYBOX_VER}.config"
	elif [ -f "/etc/kernels/busybox-custom-${BUSYBOX_VER}.config" ]
	then
		BUSYBOX_CONFIG="/etc/kernels/busybox-custom-${BUSYBOX_VER}.config"
	elif [ -f "${CONFIG_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_DIR}/busybox.config"
	elif [ -f "${CONFIG_GENERIC_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_GENERIC_DIR}/busybox.config"
	elif [ "${DEFAULT_BUSYBOX_CONFIG}" != "" -a -f "${DEFAULT_BUSYBOX_CONFIG}" ]
	then
		BUSYBOX_CONFIG="${DEFAULT_BUSYBOX_CONFIG}"
	else
		die 'Error: No busybox .config specified, or file not found!'
	fi

	cd "${TEMP}"
	rm -rf ${BUSYBOX_DIR} > /dev/null
	unpack ${BUSYBOX_SRCTAR} || die 'Could not extract busybox source tarball!'
	[ -d "${BUSYBOX_DIR}" ] || die 'Busybox directory ${BUSYBOX_DIR} is invalid!'

	cd "${BUSYBOX_DIR}"
	cp "${BUSYBOX_CONFIG}" .config
   
	print_info 1 'busybox: >> Configuring...'
	if logicTrue $(profile_get_key busybox-menuconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running busybox menuconfig..."
		compile_generic runtask ${KERNEL_ARGS} menuconfig
		[ "$?" ] || die 'Error: busybox menuconfig failed!'
		
		if [ -w /etc/kernels ]
		then
			profile_set_key busybox-config-destination-path "/etc/kernels"
		else
			print_info 1 ">> Busybox config install path: ${BOLD}/etc/kernels ${NORMAL}is not writeable attempting to use ${TEMP}/genkernel-output"
			if [ ! -w ${TEMP} ]
			then
				die "Could not write to ${TEMP}/genkernel-output."
			else
				mkdir -p ${TEMP}/genkernel-output || die "Could not make ${TEMP}/genkernel-output."
				profile_set_key busybox-config-destination-path "${TEMP}/genkernel-output"
			fi
		fi
		cp .config "$(profile_get_key busybox-config-destination-path)/busybox-custom-${BUSYBOX_VER}.config"	
		print_info 1 "Custom busybox config file saved to $(profile_get_key busybox-config-destination-path)/busybox-custom-${BUSYBOX_VER}.config"

	fi
	
	# TODO Add busybox config changing support
	busybox_config_set ".config" "CONFIG_FEATURE_INSTALLER" "y"

	# turn on/off the cross compiler
	if [ -n "$(profile_get_key cross-compile)" ]
	then
		busybox_config_set ".config" "USING_CROSS_COMPILER" "y"
		busybox_config_set ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key cross-compile)"
    elif [ -n "$(profile_get_key utils-cross-compile)" ]
	then
		busybox_config_set ".config" "USING_CROSS_COMPILER" "y"
		busybox_config_set ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	else
		busybox_config_unset ".config" "USING_CROSS_COMPILER"
		busybox_config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi
	
	yes '' 2>/dev/null | compile_generic oldconfig

	
	print_info 1 'busybox: >> Compiling...'
	compile_generic all

	
	[ -f "busybox" ] || die 'Busybox executable does not exist!'
	strip "busybox" || die 'Could not strip busybox binary!'
	
	[ -e "${TEMP}/busybox-compile" ] && rm -r ${TEMP}/busybox-compile
	mkdir ${TEMP}/busybox-compile
	
	cp busybox ${BUSYBOX_CONFIG} ${TEMP}/busybox-compile
	cd ${TEMP}/busybox-compile
	genkernel_generate_package "busybox-${BUSYBOX_VER}" "."

	cd "${TEMP}"
	rm -rf "${BUSYBOX_DIR}" > /dev/null
}


# Busybox specific functions
busybox_config_set() {
    #TODO need to check for null entry entirely
    sed -i ${1} -e "s|#\? \?${2} is.*|${2}=${3}|g"
    sed -i ${1} -e "s|${2}=.*|CONFIG_${2}=${3}|g"
    if ! busybox_config_is_set ${1} ${2}
    then
        echo "${2}=${3}" >>  ${1}
    fi
}

busybox_config_unset() {
    sed -i ${1} -e "s/${2}=.*/# CONFIG_${2} is not set/g"
}


busybox_config_is_set() {
    local RET_STR
    RET_STR=$(grep ${2}= ${1})
    [ "${RET_STR%%=*}=" == "$2=" ] && return 0 || return 1
}

busybox_config_is_not_set() {
    local RET_STR
    RET_STR=$(grep ${2} ${1})
    [ "${RET_STR}" == "# $2 is not set" ] && return 0
    [ "${RET_STR}" == "" ] && return 0
    return 1
}

