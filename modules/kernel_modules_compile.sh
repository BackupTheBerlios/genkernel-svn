require kernel_config
kernel_modules_compile::()
{
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
		if [ 	"$(profile_get_key arch-override)" == "um" -o "$(profile_get_key arch-override)" == "xen0" \
			-o "$(profile_get_key arch-override)" == "xenU" ]
		then
			die "Compiling for ARCH=$(profile_get_key arch-override) requires kbuild_output to differ from the kernel-tree"
		fi
	fi

	# Kernel cross compiling support
	[ -n "$(profile_get_key kernel-cross-compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(profile_get_key kernel-cross-compile)"

	cd $(profile_get_key kernel-tree)

	# make the modules	
	print_info 1 '>> Compiling kernel modules ...'
	compile_generic ${ARGS} modules
}
