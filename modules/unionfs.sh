require @pkg_unionfs-${UNIONFS_VER}-tools:null:unionfs_tools_compile
require unionfs_modules_compile

unionfs::()
{
	genkernel_convert_tar_to_cpio "unionfs" "${UNIONFS_VER}-tools"
	genkernel_convert_tar_to_cpio "unionfs" "${UNIONFS_VER}-modules-${KV_FULL}"

}
