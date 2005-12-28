get_KV() {
	KERNEL_DIR="$1"
	if [ "$(config_get_key no-kernel-sources)" = 'true' -a -e "$(config_get_key kerncache)" ]
	then
		/bin/tar -xj -C ${TEMP} -f "$(config_get_key kerncache)" kerncache.config 
		if [ -e ${TEMP}/kerncache.config ]
		then
			VER=`grep ^VERSION\ \= ${TEMP}/kerncache.config | awk '{ print $3 };'`
			PAT=`grep ^PATCHLEVEL\ \= ${TEMP}/kerncache.config | awk '{ print $3 };'`
			SUB=`grep ^SUBLEVEL\ \= ${TEMP}/kerncache.config | awk '{ print $3 };'`
			EXV=`grep ^EXTRAVERSION\ \= ${TEMP}/kerncache.config | sed -e "s/EXTRAVERSION =//" -e "s/ //g"`
			if [ "${PAT}" -ge '6' -a "${VER}" -ge '2' ]
			then
				LOV=`grep ^CONFIG_LOCALVERSION\= ${TEMP}/kerncache.config | sed -e "s/CONFIG_LOCALVERSION=\"\(.*\)\"/\1/"`
				KV=${VER}.${PAT}.${SUB}${EXV}${LOV}
			else
				die 'Kernel unsupported (2.6 or newer needed); exiting.'
			fi

		else
			die "Could not find kerncache.config in the kernel cache! Exiting."
		fi
	elif [ "$(config_get_key no-kernel-sources)" = 'true' ]
	then
		die '--no-kernel-sources requires a valid --kerncache!'
	else
		# Configure the kernel
		# If BUILD_KERNEL=0 then assume --no-clean, menuconfig is cleared

		VER=`grep ^VERSION\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		PAT=`grep ^PATCHLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		SUB=`grep ^SUBLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
		EXV=`grep ^EXTRAVERSION\ \= ${KERNEL_DIR}/Makefile | sed -e "s/EXTRAVERSION =//" -e "s/ //g"`
		if [ "${PAT}" -ge '6' -a "${VER}" -ge '2' -a -e ${KERNEL_DIR}/.config ]
		then
			if [ -f ${KERNEL_DIR}/include/linux/version.h ]
			then
				UTS_RELEASE=`grep UTS_RELEASE ${KERNEL_DIR}/include/linux/version.h | sed -e 's/#define UTS_RELEASE "\(.*\)"/\1/'`
				LOV=`echo ${UTS_RELEASE}|sed -e "s/${VER}.${PAT}.${SUB}${EXV}//"`
				KV=${VER}.${PAT}.${SUB}${EXV}${LOV}
			else
				LCV=`grep ^CONFIG_LOCALVERSION= ${KERNEL_DIR}/.config | sed -r -e "s/.*=\"(.*)\"/\1/"`
				KV=${VER}.${PAT}.${SUB}${EXV}${LCV}
			fi
		elif [ "${PAT}" -lt '6' -a "${VER}" -eq '2' ]
		then
			die 'Kernel unsupported (2.6 or newer needed); exiting.'
		fi
	fi
}

genkernel_lookup_kernel() {
	local myTree
	myTree=$(config_get_key kernel-tree)

	[ ! -e ${myTree}/Makefile ] && die 'Kernel source tree invalid, no Makefile found!'
	get_KV "${myTree}" # Validate ${myTree} into ${KERNEL_DIR}

	# Decide whether to keep config or update it
	# If the tree looks good provide it...

	NORMAL=${BOLD} print_info 1 "Kernel Tree: Linux Kernel ${BOLD}${KV}${NORMAL} for ${BOLD}${ARCH}${NORMAL}..."
	provide kernel_src_tree
}
