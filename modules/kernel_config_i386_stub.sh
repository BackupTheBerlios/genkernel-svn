require @kernel_src_tree:null:fail
kernel_config_i386_stub::()
{
	setup_kernel_args


	cd $(profile_get_key kernel-tree)

	# CLEAN
	# Source dir needs to be clean or kbuild complains
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		compile_generic mrproper
	fi

	# Setup fake i386 kbuild_output for arch=um or xen0 or xenU 
	# Some proggies need a i386 configured kernel tree
	#if [ 	"$(profile_get_key arch)" == "um" -o "$(profile_get_key arch-override)" == "xen0" \
	#	 -o "$(profile_get_key arch-override)" == "xenU" ]
	#then
	#	print_info 1 "${PRINT_PREFIX}>> Creating $(profile_get_key arch-override)-i386 kernel environment"
	#	KRNL_TMP_DIR="${TEMP}/genkernel-kernel-$(profile_get_key arch-override)-i386"
	#	mkdir -p "${KRNL_TMP_DIR}"
	#	yes '' 2>/dev/null | compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" oldconfig
	#	compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" modules_prepare
	#fi
}
