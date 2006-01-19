require kernel_config
logicTrue $(internal_initramfs) && require initramfs_create

kernel_compile::()
{
	setup_kernel_args
	cd $(profile_get_key kbuild-output)

	# Compile the kernel image
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS} ${KERNEL_MAKE_DIRECTIVE}
}
