require @pkg_open-iscsi.${OPENISCSI_VER}-kernel-${KV_FULL}:null:open_iscsi_compile

open_iscsi::()
{
	genkernel_convert_tar_to_cpio "open-iscsi" "${OPENISCSI_VER}-kernel-${KV_FULL}"
}

