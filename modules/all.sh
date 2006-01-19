require kernel

logicTrue $(initramfs) && require initramfs

if logicTrue $(profile_get_key install)
then
	logicTrue $(profile_get_key links) && require links
	logicTrue $(profile_get_key setgrub) && require grub
fi

all::() { true; }
