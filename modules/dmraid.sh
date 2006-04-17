require @pkg_dmraid-${DMRAID_VER}:null:dmraid_compile

dmraid::()
{
	genkernel_convert_tar_to_cpio "dmraid" "${DMRAID_VER}"
	kernel_cmdline_register 'use root=dmraid:<device> for dmraid support'
}
