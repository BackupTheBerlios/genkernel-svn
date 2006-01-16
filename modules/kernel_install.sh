require kernel_compile
kernel_install::()
{
	local ARGS CP_ARGS
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

	# Set the destination path for the kernel
	if [ -n "$(profile_get_key install-path)" ]
	then
		ARGS="${ARGS} INSTALL_PATH=$(profile_get_key install-path)"
		mkdir -p $(profile_get_key install-path) || die 'Failed to create install path!'
	fi
	
	cd "$(profile_get_key kbuild-output)"

	# install the kernel
	print_info 1 '>> Installing kernel ...'
	# TODO Read the directive that states where the files are being created and use that instead .. 
	#compile_generic ${ARGS} install || die "Kernel failed to install with the default install directive .. TODO fix me still"

	[ "$(profile_get_key debuglevel)" -gt "1" ] && CP_ARGS="-v"
	if [ -n "$(profile_get_key install-path)" ]
	then
		cp ${CP_ARGS} "$(profile_get_key kernel-binary)" "$(profile_get_key install-path)"
		cp ${CP_ARGS} "System.map" "$(profile_get_key install-path)"

	else
		# TODO need to get kname-arch-kv yet....
		cp ${CP_ARGS} "$(profile_get_key kernel-binary)" /boot
		cp ${CP_ARGS} "System.map" /boot
	fi
}
