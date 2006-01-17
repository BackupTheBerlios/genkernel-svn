require kernel_config
kernel_modules_compile::()
{
	setup_kernel_args

	cd $(profile_get_key kernel-tree)

	# make the modules	
	print_info 1 '>> Compiling kernel modules ...'
	compile_generic ${ARGS} modules
}
