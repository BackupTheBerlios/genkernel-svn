require kernel_modules_compile
kernel_modules_install::()
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

	# Set the destination path for the modules
	if [ -n "$(profile_get_key install-mod-path)" ]
	then
		ARGS="${ARGS} INSTALL_MOD_PATH=$(profile_get_key install-mod-path)"
		mkdir -p $(profile_get_key install-mod-path) || die 'Failed to create module install path!'
		[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel modules to $(profile_get_key install-mod-path)"
	else
		[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel modules to /"
	fi

	cd $(profile_get_key kernel-tree)

	# install the modules	
	print_info 1 '>> Installing kernel modules (if necessary) ...'
	compile_generic ${ARGS} modules_install
}
