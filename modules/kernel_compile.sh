require kernel_config

logicTrue $(profile_get_key internal-initramfs) && require initramfs

kernel_compile::()
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

	cd $(profile_get_key kbuild-output)
	config_set_string "INITRAMFS_SOURCE" "${TEMP}/initramfs-internal ${TEMP}/initramfs-internal.devices"
	# make the kernel
	# FIXME: Needs to use KERNEL_MAKE_DIRECTIVE
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS} ${KERNEL_MAKE_DIRECTIVE}
}
