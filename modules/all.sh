require kernel

logicTrue $(initramfs) && require initramfs

if logicTrue $(profile_get_key install) 
then
	logicTrue $(profile_get_key links) && require links
	logicTrue $(profile_get_key setgrub) && require grub
fi

all::() { 


cfg_register_read
kernel_cmdline_register_read

print_info 1 'Do NOT report kernel bugs as genkernel bugs unless your bug'
print_info 1 'is about the default genkernel configuration...'
print_info 1 ''
print_info 1 'Make sure you have the latest genkernel before reporting bugs.'
print_info 1 ''


}
