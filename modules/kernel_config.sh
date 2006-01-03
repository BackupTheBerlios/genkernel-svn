kernel_config::()
{
	# config_set_key kbuild-output '/tmp/genkernel/2.6.14'
	# config_set_key arch 'i386'
	# config_set_key install-path '/tmp/genkernel/2.6.14/output'
	# config_set_key install-mod-path '/tmp/genkernel/2.6.14/output'

	mkdir -p $(config_get_key install-path) || die 'Failed to create install path!'
	mkdir -p $(config_get_key install-mod-path) || die 'Failed to create module install path!'

	cd $(config_get_key kernel-tree)
	# Source dir needs to be clean or kbuild complains

	[ -n "$(config_get_key arch-override)" ] && ARGS="${ARGS} ARCH=$(config_get_key arch-override)"
	if [ -n "$(config_get_key kbuild-output)" ]
	then
		ARGS="${ARGS} KBUILD_OUTPUT=$(config_get_key kbuild-output)"
		mkdir -p $(config_get_key kbuild-output)
	fi
	if [ -n "$(config_get_key install-path)" ]
	then
		ARGS="${ARGS} INSTALL_PATH=$(config_get_key install-path)"
		mkdir -p $(config_get_key install-path)
	fi
	if [ -n "$(config_get_key install-mod-path)" ]
	then
		ARGS="${ARGS} INSTALL_MOD_PATH=$(config_get_key install-mod-path)"
		mkdir -p $(config_get_key install-mod-path)
	fi
	[ -n "$(config_get_key kernel-cross-compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(config_get_key kernel-cross-compile)"
	compile_generic distclean

	# mrproper needed?
	[ -n "$(config_get_key mrproper)" ] && compile_generic ${ARGS} mrproper

	yes '' 2>/dev/null | compile_generic ${ARGS} oldconfig
	compile_generic ${ARGS}
	compile_generic ${ARGS} modules
	compile_generic ${ARGS} install
	compile_generic ${ARGS} modules_install
}
