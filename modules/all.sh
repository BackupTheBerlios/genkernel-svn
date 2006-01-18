
require kernel
require initramfs

logicTrue $(profile_get_key links) && require links
logicTrue $(profile_get_key setgrub) && require grub

all::() { true; }
