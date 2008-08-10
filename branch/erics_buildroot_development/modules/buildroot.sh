require @pkg_buildroot-${BUILDROOT_VER}-$(profile_get_key utils-arch)-toolchain:null:buildroot_compile 
buildroot::() {
    local BUILDROOT_DIR="buildroot"
    cd ${CACHE_DIR}
    if [ ! -d "${BUILDROOT_DIR}-$(profile_get_key utils-arch)" ]
    then
        mkdir -p "${BUILDROOT_DIR}-$(profile_get_key utils-arch)"
        cd "${BUILDROOT_DIR}-$(profile_get_key utils-arch)"
        genkernel_extract_package "buildroot-${BUILDROOT_VER}-$(profile_get_key utils-arch)-toolchain"
    fi

    cd "${BUILDROOT_DIR}-$(profile_get_key utils-arch)"
    # build extra packages that the user might want
    cp .config.gk .config

    #config_set .config BR2_PACKAGE_FLEX y
    #config_set .config BR2_PACKAGE_FLEX_LIBFL y
    #config_unset .config BR2_HOST_FAKEROOT
    #config_set .config BR2_PACKAGE_LIBGMP y
    #config_set .config BR2_PACKAGE_BRIDGE y
    #config_set .config BR2_PACKAGE_DROPBEAR y
    ##config_set .config BR2_PACKAGE_IPTABLES y
    #config_set .config BR2_PACKAGE_NCFTP y
    #config_set .config BR2_PACKAGE_NCFTP_GET y
    #config_set .config BR2_PACKAGE_NCFTP_PUT y
    #config_set .config BR2_PACKAGE_NCFTP_LS y
    #config_set .config BR2_PACKAGE_NCFTP_BATCH y
    #config_set .config BR2_PACKAGE_NETKITBASE y
    #config_set .config BR2_PACKAGE_NFS_UTILS y
    #config_set .config BR2_PACKAGE_NFS_UTILS_RPCDEBUG y
    #config_set .config BR2_PACKAGE_NFS_UTILS_RPC_LOCKD y
    #config_set .config BR2_PACKAGE_NFS_UTILS_RPC_RQUOTAD y
    #config_set .config BR2_PACKAGE_OPENSSL y
    #config_set .config BR2_PACKAGE_OPENVPN y
    ##config_set .config BR2_PACKAGE_OPENSWAN y
    #config_set .config BR2_PACKAGE_PORTMAP y
    #config_set .config BR2_PACKAGE_PPPD y
    #config_set .config BR2_PACKAGE_RP_PPPOE y
    #config_set .config BR2_PACKAGE_PPTP_LINUX y
    #config_set .config BR2_PACKAGE_VTUN y
    #config_set .config BR2_PACKAGE_WIRELESS_TOOLS y
    #config_set .config BR2_PACKAGE_DM y
    #config_set .config BR2_PACKAGE_MDADM y
    #config_set .config BR2_PACKAGE_RAIDTOOLS y
    ##config_set .config BR2_PACKAGE_USBUTILS y
    #config_set .config BR2_PACKAGE_XFSPROGS y
    #config_set .config BR2_PACKAGE_LZO y
    #config_set .config BR2_PACKAGE_MICROPERL y
    #

    logicTrue $(profile_get_key busybox) \
        && print_info 1 'BUILDROOT (Packages): > Enabling busybox...' \
        && config_set .config BR2_PACKAGE_BUSYBOX y
    logicTrue $(profile_get_key lvm2) \
        && print_info 1 'BUILDROOT (Packages): > Enabling lvm2...' \
        && config_set .config BR2_PACKAGE_LVM2 y
    if logicTrue $(profile_get_key e2fsprogs)
    then
        print_info 1 'BUILDROOT (Packages): > Enabling E2FSPROGS...'
        config_set .config BR2_PACKAGE_E2FSPROGS y
        config_set .config BR2_PACKAGE_E2FSPROGS_BADBLOCKS y
        config_set .config BR2_PACKAGE_E2FSPROGS_BLKID y
        config_set .config BR2_PACKAGE_E2FSPROGS_CHATTR y
        config_set .config BR2_PACKAGE_E2FSPROGS_DUMPE2FS y
        config_set .config BR2_PACKAGE_E2FSPROGS_E2FSCK y
        config_set .config BR2_PACKAGE_E2FSPROGS_E2LABEL y
        config_set .config BR2_PACKAGE_E2FSPROGS_FILEFRAG y
        config_set .config BR2_PACKAGE_E2FSPROGS_FINDFS y
        config_set .config BR2_PACKAGE_E2FSPROGS_FSCK y
        config_set .config BR2_PACKAGE_E2FSPROGS_LOGSAVE y
        config_set .config BR2_PACKAGE_E2FSPROGS_LSATTR y
        config_set .config BR2_PACKAGE_E2FSPROGS_MKE2FS y
        config_set .config BR2_PACKAGE_E2FSPROGS_MKLOSTFOUND y
        config_set .config BR2_PACKAGE_E2FSPROGS_TUNE2FS y
        config_set .config BR2_PACKAGE_E2FSPROGS_UUIDGEN y
    fi
    logicTrue $(profile_get_key portmap) \
        && print_info 1 'BUILDROOT (Packages): > Enabling portmap...' \
        && config_set .config BR2_PACKAGE_PORTMAP y
    logicTrue $(profile_get_key dmraid) \
        && print_info 1 'BUILDROOT (Packages): > Enabling dmraid...' \
        && config_set .config BR2_PACKAGE_DMRAID y
    #logicTrue $(profile_get_key open-iscsi) && require open_iscsi
    #logicTrue $(profile_get_key aoetools) && require aoetools
    #logicTrue $(profile_get_key luks) && require luks

    # Clean out destination target so we only get the packages we want
    rm -rf "project_build_$(profile_get_key utils-arch)/uclibc/root"

    # Buildroot gets mad if this directory doesnt exist... 
    mkdir -p "project_build_$(profile_get_key utils-arch)/uclibc/root/usr/lib"

    print_info 1 'BUILDROOT (Packages): > Compiling...'
    compile_generic
    cd "project_build_$(profile_get_key utils-arch)/uclibc/root"
    # Remove extra buildroot stuff we dont care about
    # Remove etc/motd eg....
    rm etc/br-version
    rm etc/hostname
    rm etc/issue


    genkernel_generate_cpio_path buildroot-core .
    initramfs_register_cpio buildroot-core
}
