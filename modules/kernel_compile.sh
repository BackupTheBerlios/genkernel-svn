require kernel_config
logicTrue $(internal_initramfs) && require initramfs_create

kernel_compile::()
{
	setup_kernel_args
	cd $(profile_get_key kbuild-output)

	# Compile the kernel image
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${ARGS} ${KERNEL_MAKE_DIRECTIVE}

	# Save messages for final display
	messages_register ''
	messages_register "Kernel compiled successfully!"
	messages_register ''
	messages_register 'Required Kernel Parameters:'


    if [ "${BUILD_INITRD}" -eq '0' ]
    then
        print_info 1 '    root=/dev/$ROOT'
        print_info 1 '    [ And "vga=0x317 splash=verbose" if you use a framebuffer ]'
        print_info 1 ''
        print_info 1 '    Where $ROOT is the device node for your root partition as the'
        print_info 1 '    one specified in /etc/fstab'
    elif [ "${KERN_24}" != '1' -a  "${CMD_BOOTSPLASH}" != '1' ]
    then
        print_info 1 '    real_root=/dev/$ROOT'
        print_info 1 ''
        print_info 1 '    Where $ROOT is the device node for your root partition as the'
        print_info 1 '    one specified in /etc/fstab'
        print_info 1 ''
        print_info 1 "If you require Genkernel's hardware detection features; you MUST"
        print_info 1 'tell your bootloader to use the provided INITRAMFS file. Otherwise;'
        print_info 1 'substitute the root argument for the real_root argument if you are'
        print_info 1 'not planning to use the initrd...'
    else
        print_info 1 '    root=/dev/ram0 real_root=/dev/$ROOT init=/linuxrc'
        [ "${INITRD_SIZE}" -ge 4096 ] && print_info 1 "    ramdisk_size=${INITRD_SIZE}"
        print_info 1 ''
        print_info 1 '    Where $ROOT is the device node for your root partition as the'
        print_info 1 '    one specified in /etc/fstab'
        print_info 1 ''
        print_info 1 "If you require Genkernel's hardware detection features; you MUST"
        print_info 1 'tell your bootloader to use the provided INITRD file. Otherwise;'
        print_info 1 'substitute the root argument for the real_root argument if you are'
        print_info 1 'not planning to use the initrd...'
    fi

}
