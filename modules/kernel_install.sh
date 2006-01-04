require kernel_compile
kernel_install::()
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
	
	# Kernel cross compiling support
	#[ -n "$(config_get_key kernel-cross-compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(config_get_key kernel-cross-compile)"

	cd $(config_get_key kernel-tree)

	# install the kernel
	print_info 1 '>> Installing kernel ...'
	# TODO Read the directive that states where the files are being created and use that instead .. 
	compile_generic ${ARGS} install || die "Kernel failed to install with the default install directive .. TODO fix me still"
}
