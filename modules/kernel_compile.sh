require kernel_config
logicTrue $(internal_initramfs) && require initramfs_create

kernel_compile::()
{
	setup_kernel_args
	cd $(profile_get_key kbuild-output)

	# Compile the kernel image
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${KERNEL_ARGS} ${KERNEL_MAKE_DIRECTIVE}

	# Save messages for final display
	messages_register ''
	messages_register "Kernel compiled successfully!"
	messages_register ''
	messages_register 'Required Kernel Parameters:'
    messages_register '    root=/dev/$ROOT'
    messages_register '    [ And "vga=0x317 splash=verbose" if you use a framebuffer ]'
    messages_register ''
    messages_register '    Where $ROOT is the device node for your root partition as the'
    messages_register '    one specified in /etc/fstab'
}
