require open_iscsi_modules_compile

# warn about missing kernel configuration options
cfg_register "CRYPTO" "REQUIRED for open-iscsi"
cfg_register "CRYPTO_CRC32C" "REQUIRED for open-iscsi"

# Note the iscsistart program is compiled via buildroot support.
# The version of iscsi used here and the tool must be the same.
# This module only supports kernel 2.6.26+

open_iscsi::()
{
    genkernel_convert_tar_to_cpio "open-iscsi" "${OPENISCSI_VER}-modules-${KV_FULL}"
    cd $(profile_get_key install-to-prefix)
    [ ! -w "$(profile_get_key install-to-prefix)" ] \
        && die "Could not write to $(profile_get_key install-to-prefix).  Set install-to-prefix to a writeable directory or run as root."
    genkernel_extract_package "open-iscsi-${OPENISCSI_VER}-modules-${KV_FULL}"
    print_info 1 "openiscsi:  kernel modules ${KV_FULL} installed in ${BOLD}$(profile_get_key install-to-prefix)${NORMAL}"

    print_info 1 "openiscsi: Updating module dependencies"
    if [ "$(profile_get_key debuglevel)" -gt "4" ]
    then
        /sbin/depmod -v -b $(profile_get_key install-to-prefix) ${KV_FULL}
    else
        /sbin/depmod -b $(profile_get_key install-to-prefix) ${KV_FULL}
    fi

}

