require @kernel_src_tree:null:fail
kernel_config::()
{
	# Set kbuild-output to be the same as the kernel-tree if not defined	
	#[ ! -n "$(config_get_key kbuild-output)" ] &&  config_set_key kbuild-output "$(config_get_key kernel-tree)"
	
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
		if [ 	"$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" \
			-o "$(config_get_key arch-override)" == "xenU" ]
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
		# Setup fake i386 kbuild_output for arch=um or xen0 or xenU 
		# Some proggies need a i386 configured kernel tree
		if [ 	"$(config_get_key arch-override)" == "um" -o "$(config_get_key arch-override)" == "xen0" \
			 -o "$(config_get_key arch-override)" == "xenU" ]
		then
			mkdir -p "/tmp/genkernel/$(config_get_key arch-override)-i386"
			yes '' 2>/dev/null | compile_generic ARCH=i386 "KBUILD_OUTPUT=/tmp/genkernel/$(config_get_key arch-override)-i386" oldconfig
			compile_generic ARCH=i386 "KBUILD_OUTPUT=/tmp/genkernel/$(config_get_key arch-override)-i386" prepare
		fi
	else
		# Cleanup the tree ... everything ...
		logicTrue $(config_get_key mrproper) && compile_generic ${ARGS} mrproper

		# Leave the config alone just clean up the build
		logicTrue $(config_get_key clean) && compile_generic ${ARGS} clean
	fi

	# prepare?
	#compile_generic ${ARGS} prepare
	
	# Configure
	if logicTrue $(config_get_key defconfig)
	then
		print_info 1 '>> Running defconfig...'
		compile_generic ${ARGS} defconfig
		[ "$?" ] || gen_die 'Error: defconfig failed!'
	fi
	
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
