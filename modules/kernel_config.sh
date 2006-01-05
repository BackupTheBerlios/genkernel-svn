require @kernel_src_tree:null:fail
kernel_config::()
{
	# Override the default arch being built
	[ -n "$(config_get_key arch-override)" ] && ARGS="${ARGS} ARCH=$(config_get_key arch-override)"

	# Turn off KBUILD_OUTPUT if kbuild_output is the same as the kernel tree or die if arch=um or xen0 or xenU
	if [ ! "$(config_get_key kbuild-output)" == "$(config_get_key kernel-tree)" ]
	then
		if [ -n "$(config_get_key kbuild-output)" ]
		then
			ARGS="${ARGS} KBUILD_OUTPUT=$(config_get_key kbuild-output)"
			mkdir -p $(config_get_key kbuild-output)
		fi
	elif [ "$(config_get_key kbuild-output)" == "$(config_get_key kernel-tree)" ]
	then
		if [ "${ARCH}" == "um" -o "${ARCH}" == "xen0" \
			-o "${ARCH}" == "xenU" ]
		then
			die "Compiling for ARCH=${ARCH} requires kbuild_output to differ from the kernel-tree"
		fi
	fi

	# Check that the asm-${ARCH} link is valid
	if [ "${ARCH}" == "xen0" -o "${ARCH}" == "xenU" ]
	then
		check_asm_link_ok xen || die "Bad asm link.  The output directory has already been configured for a different arch"
	elif [ "${ARCH}" == "x86" ]
	then
		check_asm_link_ok i386 || die "Bad asm link.  The output directory has already been configured for a different arch"
	else
		check_asm_link_ok ${ARCH} || die "Bad asm link.  The output directory has already been configured for a different arch"
	fi
	
	# Set the destination path for the kernel
	if [ -n "$(config_get_key install-path)" ]
	then
		ARGS="${ARGS} INSTALL_PATH=$(config_get_key install-path)"
		mkdir -p $(config_get_key install-path) || die 'Failed to create install path!'
	fi
	
	# Set the destination path for the modules
	if [ -n "$(config_get_key install-mod-path)" ]
	then
		ARGS="${ARGS} INSTALL_MOD_PATH=$(config_get_key install-mod-path)"
		mkdir -p $(config_get_key install-mod-path) || die 'Failed to create module install path!'
	fi

	# Kernel cross compiling support
	[ -n "$(config_get_key kernel-cross-compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(config_get_key kernel-cross-compile)"

	cd $(config_get_key kernel-tree)

	# CLEAN
	# Source dir needs to be clean or kbuild complains
	if [ ! "$(config_get_key kbuild-output)" == "$(config_get_key kernel-tree)" ]
	then
		compile_generic distclean
		logicTrue $(config_get_key mrproper) && compile_generic ${ARGS} mrproper
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
		# Setup fake i386 kbuild_output for arch=um or xen0 or xenU 
		# Some proggies need a i386 configured kernel tree
		if [ 	"$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" \
			 -o "$(config_get_key arch-override)" == "xenU" ]
		then
			KRNL_TMP_DIR="${TEMP}/genkernel-kernel-$(config_get_key arch-override)-i386"
			
			mkdir -p "${KRNL_TMP_DIR}"
			compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" mrproper
			yes '' 2>/dev/null | compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" oldconfig
			compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" prepare
			compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" modules_prepare
		fi
	else
		# Cleanup the tree ... everything ...
		logicTrue $(config_get_key mrproper) && compile_generic ${ARGS} mrproper

		# Leave the config alone just clean up the build
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
	fi

	
	# Configure

	if logicTrue $(config_get_key oldconfig)  # Should be default enabled
	then
		print_info 1 '>> Running oldconfig...'
		yes '' 2>/dev/null | compile_generic ${ARGS} oldconfig
		[ "$?" ] || gen_die 'Error: oldconfig failed!'
	fi
	
	# Configure
	if logicTrue $(config_get_key defconfig)
	then
		print_info 1 '>> Running defconfig...'
		compile_generic ${ARGS} defconfig
		[ "$?" ] || gen_die 'Error: defconfig failed!'
	fi

	if logicTrue $(config_get_key menuconfig)
	then 
		print_info 1 '>> Running menuconfig...'
		compile_generic runtask ${ARGS} menuconfig
		[ "$?" ] || gen_die 'Error: menuconfig failed!'
	fi

	if logicTrue $(config_get_key config)
	then 
		print_info 1 '>> Running config...'
		compile_generic runtask ${ARGS} config
		[ "$?" ] || gen_die 'Error: config failed!'
	fi
	
	if logicTrue $(config_get_key xconfig)
	then 
		print_info 1 '>> Running xconfig...'
		compile_generic ${ARGS} xconfig
		[ "$?" ] || gen_die 'Error: xconfig failed!'
	fi
	if logicTrue $(config_get_key gconfig)
	then
		print_info 1 '>> Running gconfig...'
		compile_generic ${ARGS} gconfig
		[ "$?" ] || gen_die 'Error: gconfig failed!'
	fi
	
	if logicTrue $(config_get_key allmodconfig)
	then
		print_info 1 '>> Running allmodconfig...'
		compile_generic ${ARGS} allmodconfig
		[ "$?" ] || gen_die 'Error: allmodconfig failed!'
	fi
	
	if logicTrue $(config_get_key allyesconfig)
	then
		print_info 1 '>> Running allyesconfig...'
		compile_generic ${ARGS} allyesconfig
		[ "$?" ] || gen_die 'Error: allyesconfig failed!'
	fi
	
	if logicTrue $(config_get_key allnoconfig)
	then
		print_info 1 '>> Running allnoconfig...'
		compile_generic ${ARGS} allnoconfig
		[ "$?" ] || gen_die 'Error: allnoconfig failed!'
	fi
	
	# FIXME: config_cleanup_register events need dealing with here

	# apply the ppc fix?
	if [ "$(config_get_key arch)" = 'ppc' -o "$(config_get_key arch)" = 'ppc64' ]
	then
		print_info 1 '>> Applying hack to workaround 2.6.14+ PPC header breakages...'
		compile_generic ${ARGS} 'include/asm'
	fi

	# Set or unset any config option
	#config_unset "AUDIT"
	#config_set_module "AUDIT"
	#config_set_builtin "AUDIT"
	
	# Kernel configuration may have changed our output names ..
	unset KV_FULL
	get_KV

}
