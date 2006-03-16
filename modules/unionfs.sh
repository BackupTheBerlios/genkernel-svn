require @pkg_unionfs-${UNIONFS_VER}-kernel-${KV_FULL}:null:unionfs_compile

unionfs::()
{
	genkernel_convert_tar_to_cpio "unionfs" "${UNIONFS_VER}-kernel-${KV_FULL}"

}
