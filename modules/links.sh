require kernel
logicTrue $(external_initramfs) && require initramfs


links::()
{
	local ARGS CP_ARGS KNAME

	KNAME="$(profile_get_key kernel-name)"

    if logicTrue $(profile_get_key install)
    then
		# link to the kernel
		print_info 1 ">> Creating link to kernel"
		if [ -n "$(profile_get_key install-path)" ]
		then
			print_info 1 ">> Creating link from $(profile_get_key install-path)/kernel-${KV_FULL} to $(profile_get_key install-path)/kernel"
			ln -sf "$(profile_get_key install-path)/kernel-${KV_FULL}" "$(profile_get_key install-path)/kernel"

		else
			print_info 1 ">> Creating link from /boot/kernel-${KV_FULL} to /boot/kernel"
			ln -sf "/boot/kernel-${KV_FULL}" "/boot/kernel"
		fi


		# link to the initramfs
		if logicTrue $(external_initramfs)
		then
			if [ -n "$(profile_get_key install-initramfs-path)" ]
			then
				print_info 1 ">> Creating link from $(profile_get_key install-initramfs-path)/initramfs-${KV_FULL} to $(profile_get_key install-initramfs-path)/initramfs"
				ln -sf "$(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}" "$(profile_get_key initramfs-output)/initramfs"
			else
				print_info 1 ">> Creating link from /boot/initramfs-${KV_FULL} to /boot/initramfs"
				ln -sf "/boot/initramfs-${KV_FULL}" "/boot/initramfs"
			fi
		fi


    else
        print_info 1 "Skipping link creation: --no-install enabled"
	fi
}
