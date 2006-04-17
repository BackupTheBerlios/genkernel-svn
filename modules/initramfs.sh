if logicTrue $(profile_get_key install)
then
	require initramfs_install
else
	require initramfs_create
fi

kernel_cmdline_register 'root=$DEVTYPE:$ROOT'
kernel_cmdline_register ''
kernel_cmdline_register '    Where $DEVTYPE is the type of the device containing your root'
kernel_cmdline_register '    filesystem and $ROOT is the device containing your root filesystem'
kernel_cmdline_register '    (see "man genkernel" for available device types and parameters).'
kernel_cmdline_register ''
kernel_cmdline_register '    Examples: root=block:/dev/sda1'
kernel_cmdline_register '              root=lvm2:/dev/volgroup/vol01'
kernel_cmdline_register ''

if ! logicTrue $(profile_get_key internal-initramfs)
then
	kernel_cmdline_register "If you require Genkernel's hardware detection features; you MUST"
	kernel_cmdline_register 'tell your bootloader to use the provided initramfs file.'
	kernel_cmdline_register ''
fi

initramfs::() { true; }
