require kernel_config

logicTrue $(profile_get_key internal-initramfs) && require initramfs

kernel_compile::()
{

	setup_kernel_args

	cd $(profile_get_key kbuild-output)
	config_set_string "INITRAMFS_SOURCE" "${TEMP}/initramfs-internal ${TEMP}/initramfs-internal.devices"
	# make the kernel
	# FIXME: Needs to use KERNEL_MAKE_DIRECTIVE
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS} ${KERNEL_MAKE_DIRECTIVE}
}
