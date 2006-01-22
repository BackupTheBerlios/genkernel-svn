require kernel

logicTrue $(initramfs) && require initramfs

if logicTrue $(profile_get_key install) 
then
	logicTrue $(profile_get_key links) && require links
	logicTrue $(profile_get_key setgrub) && require grub
fi

all::() { 
messages_register 'Do NOT report kernel bugs as genkernel bugs unless your bug'
messages_register 'is about the default genkernel configuration...'
messages_register ''
messages_register 'Make sure you have the latest genkernel before reporting bugs.'


messages_register_read

cfg_register_read
}
