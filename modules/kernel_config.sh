kernel_config::()
{
	# config_set_key kbuild-output '/tmp/genkernel/2.6.14'
	# config_set_key arch 'i386'
	# config_set_key install-path '/tmp/genkernel/2.6.14/output'
	# config_set_key install-mod-path '/tmp/genkernel/2.6.14/output'
	# config_set_key clean true
	# config_set_key oldconfig true
	# config_set_key menuconfig true
	# config_set_key gconfig true
	# config_set_key xconfig true

	# Override the default arch being built
	[ -n "$(config_get_key arch-override)" ] && ARGS="${ARGS} ARCH=$(config_get_key arch-override)"

	# Turn off KBUILD_OUTPUT if kbuild_output is the same as the kernel tree
	if [ ! "$(config_get_key kbuild_output)" == "$(config_get_key kernel-tree)" ]
	then
		if [ -n "$(config_get_key kbuild-output)" ]
		then
			ARGS="${ARGS} KBUILD_OUTPUT=$(config_get_key kbuild-output)"
			mkdir -p $(config_get_key kbuild-output)
		fi
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
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
	else
		logicTrue $(config_get_key mrproper) && compile_generic ${ARGS} mrproper
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
	fi

	# prepare?
	compile_generic ${ARGS} prepare
	
	# Configure
	if logicTrue $(config_get_key oldconfig)
	then
		print_info 1 '>> Running oldconfig...'
		yes '' 2>/dev/null | compile_generic ${ARGS} oldconfig
		[ "$?" ] || gen_die 'Error: oldconfig failed!'
	fi

	if logicTrue $(config_get_key menuconfig)
	then 
		compile_generic runtask ${ARGS} menuconfig
		[ "$?" ] || gen_die 'Error: menuconfig failed!'
	fi

	if logicTrue $(config_get_key xconfig)
	then 
		compile_generic ${ARGS} xconfig
		[ "$?" ] || gen_die 'Error: xconfig failed!'
	fi
	if logicTrue $(config_get_key gconfig)
	then
		compile_generic ${ARGS} gconfig
		[ "$?" ] || gen_die 'Error: gconfig failed!'
	fi

	# Override the config???

	# apply the ppc fix?
	if [ "$(config_get_key arch)" = 'ppc' -o "$(config_get_key arch)" = 'ppc64' ]
	then
		echo 'Applying hack to workaround 2.6.14+ PPC header breakages...'
		compile_generic ${ARGS} 'include/asm'
	fi

	# make the modules	
	compile_generic ${ARGS} modules
	
	# install the modules	
	compile_generic ${ARGS} modules_install
	
	# Create the initramfs 
	# Optionally pack the initramfs into the kernel sources 
	
	# make the kernel
	compile_generic ${ARGS}
	
	# install the kernel
	compile_generic ${ARGS} install
}
