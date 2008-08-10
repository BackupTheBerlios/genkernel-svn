logicTrue $(profile_get_key mountboot) && require mount_boot
require kernel
logicTrue $(initramfs) && require initramfs
logicTrue $(profile_get_key links) && require links
logicTrue $(profile_get_key setgrub) && require grub

all::() { 

print_info 1 ">> The output files were placed in:"
print_info 1 "   ${BOLD}$(profile_get_key install-to-prefix)${NORMAL}"

cfg_register_read
kernel_cmdline_register_read

if [ -n "$(profile_get_key kbuild-output)" ]
then
    print_info 1 "Kbuild was used for the kernel and modules"
    print_info 1 "export KBUILD_OUTPUT=$(profile_get_key kbuild-output)"
fi
print_info 1 ">> Genkernel completed successfully..."
}
