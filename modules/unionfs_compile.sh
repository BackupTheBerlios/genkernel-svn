require kernel_config
#logicTrue $(profile_get_key internal-uclibc) && require gcc

unionfs_compile::()
{
	local UNIONFS_SRCTAR="${SRCPKG_DIR}/unionfs-${UNIONFS_VER}.tar.gz" UNIONFS_DIR="unionfs-${UNIONFS_VER}"	
	if kernel_config_is_not_set "MODULES"
	then
		print_info 1 ">> Modules not enabled in .config .. skipping unionfs compile"
	else

		cd "${TEMP}"
		rm -rf ${UNIONFS_DIR} > /dev/null
		unpack ${UNIONFS_SRCTAR} || die 'Could not extract unionfs source tarball!'
		[ -d "${UNIONFS_DIR}" ] || die 'Unionfs directory ${UNIONFS_DIR} is invalid!'
		cd "${UNIONFS_DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/unionfs/${UNIONFS_VER} .
		
		echo "ARCH=${ARCH}" > fistdev.mk
		echo "PREFIX=${TEMP}/unionfs-build" >> fistdev.mk
		echo "EXTRAUCFLAGS=-static" >> fistdev.mk
		
		if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
		then
			echo "KBUILD_OUTPUT=$(profile_get_key kbuild-output)" >> fistdev.mk
		fi

		# turn on/off the cross compiler
		if [ "$(profile_get_key cross-compile)" != "" ]
		then
			echo "KERNEL_CROSS_COMPILE=$(profile_get_key cross-compile)" >> fistdev.mk
			echo "UTILS_CROSS_COMPILE=$(profile_get_key cross-compile)" >> fistdev.mk
		else
			if [ "$(profile_get_key utils-cross-compile)" != "" ]
			then
				echo "UTILS_CROSS_COMPILE=$(profile_get_key cross-compile)" >> fistdev.mk
    		fi
		fi

		print_info 1 "Compiling unionfs kernel module"
		compile_generic unionfs.ko

		print_info 1 "Compiling unionfs utilities"
		compile_generic utils

		[ -e ${TEMP}/unionfs-output ] && rm -r ${TEMP}/unionfs-output
		mkdir -p ${TEMP}/unionfs-output/sbin
		mkdir -p ${TEMP}/unionfs-output/lib/modules
		cp unionfs.ko ${TEMP}/unionfs-output/lib/modules
		
		#cp unionimap ${TEMP}/unionfs-output/sbin
		cp unionctl ${TEMP}/unionfs-output/sbin
		#cp uniondbg ${TEMP}/unionfs-output/sbin
		#strip ${TEMP}/unionfs-output/sbin/unionimap
		strip ${TEMP}/unionfs-output/sbin/unionctl
		#strip ${TEMP}/unionfs-output/sbin/uniondbg
		
		cd ${TEMP}/unionfs-output
		genkernel_generate_package "unionfs-${UNIONFS_VER}-kernel-${KV_FULL}" "."
		#genkernel_generate_cpio_path "unionfs-${UNIONFS_VER}" .
		#initramfs_register_cpio "unionfs-${UNIONFS_VER}"

		

	fi
}
