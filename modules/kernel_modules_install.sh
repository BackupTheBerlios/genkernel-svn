require kernel_modules_compile
kernel_modules_install::()
{

	if kernel_config_is_not_set "MODULES"
	then
		print_info 1 ">> Modules not enabled in .config .. skipping modules install"
	else

		setup_kernel_args

		# Set the destination path for the modules
		if [ -n "$(profile_get_key install-mod-path)" ]
		then
			[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel modules to $(profile_get_key install-mod-path)"
		else
			[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel modules to /"
		fi

		cd $(profile_get_key kernel-tree)

		# install the modules
		print_info 1 '>> Installing kernel modules ...'
		compile_generic ${ARGS} modules_install
	fi
}
