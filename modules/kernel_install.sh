require kernel_compile

kernel_install::()
{
	local ARGS CP_ARGS

	setup_kernel_args

	cd "$(profile_get_key kbuild-output)"

    if logicTrue $(profile_get_key install)
    then
		# install the kernel
		print_info 1 '>> Installing kernel ...'
		# TODO Read the directive that states where the files are being created and use that instead .. 
		#compile_generic ${ARGS} install || die "Kernel failed to install with the default install directive .. TODO fix me still"

		[ "$(profile_get_key debuglevel)" -gt "1" ] && CP_ARGS="-v"
		if [ -n "$(profile_get_key install-path)" ]
		then
			[ "$(profile_get_key debuglevel)" -gt "1" ] &&\
				print_info 1 ">> Installing kernel to $(profile_get_key install-path)/kernel-${KNAME}-${ARCH}-${KV_FULL}"
			cp ${CP_ARGS} "$(profile_get_key kernel-binary)" "$(profile_get_key install-path)/kernel-${KNAME}-${ARCH}-${KV_FULL}"
			cp ${CP_ARGS} "System.map" "$(profile_get_key install-path)/System.map-${KNAME}-${ARCH}-${KV_FULL}"

		else
			# TODO need to get kname-arch-kv yet....
			[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel to /boot/kernel-${KNAME}-${ARCH}-${KV_FULL}"
			cp ${CP_ARGS} "$(profile_get_key kernel-binary)" "/boot/kernel-${KNAME}-${ARCH}-${KV_FULL}"
			cp ${CP_ARGS} "System.map" "/boot/System.map-${KNAME}-${ARCH}-${KV_FULL}"
		fi
    else
        print_info 1 "Skipping installation of the kernel: --no-install enabled"
	fi
}
