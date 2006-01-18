require kernel_config
logicTrue $(profile_get_key internal-initramfs) && require initramfs_create

kernel_compile::()
{
	setup_kernel_args
	cd $(profile_get_key kbuild-output)

	# Turn set the initramfs_source string if building an internal initramfs
	if logicTrue $(profile_get_key internal-initramfs) 
	then
		kernel_config_set_string "INITRAMFS_SOURCE" "${TEMP}/initramfs-internal ${TEMP}/initramfs-internal.devices"
	else
		kernel_config_unset
	fi

	# Compile the kernel image
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS} ${KERNEL_MAKE_DIRECTIVE}
}
