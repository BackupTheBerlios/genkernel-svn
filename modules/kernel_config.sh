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
		if [ "$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" -o "$(config_get_key arch-override)" == "xenU" ]
		then
			die "Compiling for ARCH=$(config_get_key arch-override) requires kbuild_output to differ from the kernel-tree"
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
		# Cleanup the tree ... everything ...
		logicTrue $(config_get_key mrproper) && compile_generic ${ARGS} mrproper

		# Leave the config alone just clean up the build
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
	fi

	if [ "$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" -o "$(config_get_key arch-override)" == "xenU" ]
	then
		# We must use kbuild for arch um or xen0 or xenU .. 
		compile_generic distclean
		mkdir -p /tmp/genkernel/um-i386-foo
		yes '' 2>/dev/null | compile_generic ARCH=i386 KBUILD_OUTPUT=/tmp/genkernel/um-i386-foo oldconfig
		compile_generic ARCH=i386 KBUILD_OUTPUT=/tmp/genkernel/um-i386-foo prepare
	fi
		
	# prepare?
	#compile_generic ${ARGS} prepare
	
	# Configure
	if logicTrue $(config_get_key oldconfig)
	then
		print_info 1 '>> Running oldconfig...'
		yes '' 2>/dev/null | compile_generic ${ARGS} oldconfig
		[ "$?" ] || gen_die 'Error: oldconfig failed!'
	fi

	if logicTrue $(config_get_key menuconfig)
	then 
		print_info 1 '>> Running menuconfig...'
		compile_generic runtask ${ARGS} menuconfig
		[ "$?" ] || gen_die 'Error: menuconfig failed!'
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

	# Override the config???

	# apply the ppc fix?
	if [ "$(config_get_key arch)" = 'ppc' -o "$(config_get_key arch)" = 'ppc64' ]
	then
		print_info 1 '>> Applying hack to workaround 2.6.14+ PPC header breakages...'
		compile_generic ${ARGS} 'include/asm'
	fi

	# make the modules	
	print_info 1 '>> Compiling kernel modules (if necessary) ...'
	compile_generic ${ARGS} modules
	
	# install the modules	
	print_info 1 '>> Installing kernel modules (if necessary) ...'
	compile_generic ${ARGS} modules_install
	
	# Create the initramfs 
	# Optionally pack the initramfs into the kernel sources 
	
	# make the kernel
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS}
	
	# install the kernel
	if [ ! "$(config_get_key arch-override)" == "um" ]
	then
		print_info 1 '>> Installing kernel ...'
		compile_generic ${ARGS} install
	fi
}
