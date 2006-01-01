require @pkg_lvm2-${LVM2_VER}:null:lvm2_compile

lvm2::()
{
	genkernel_convert_tar_to_cpio "lvm2" "${LVM2_VER}"
}
