require @pkg_buildroot-${BUILDROOT_VER}-$(profile_get_key utils-arch)-toolchain:null:buildroot_compile 


if logicTrue $(profile_get_key lvm2)
then
	cfg_register "BLK_DEV_DM" "REQUIRED for a fully functional lvm"
	cfg_register "DM_SNAPSHOT" "Recommended for a fully functional lvm"
	cfg_register "DM_MIRROR" "Recommended for a fully functional lvm"
fi

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
    config_set .config BR2_PACKAGE_DROPBEAR y

    if logicTrue $(profile_get_key busybox) 
    then
        print_info 1 'BUILDROOT (Packages): > Enabling busybox...'
        config_set .config BR2_PACKAGE_BUSYBOX y
	config_set package/busybox/busybox-1.11.x.config CONFIG_DEPMOD y
        config_set package/busybox/busybox-1.11.x.config CONFIG_RAIDAUTORUN y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MOUNT_NFS y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FDISK y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_FDISK_WRITABLE y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_FDISK_ADVANCED y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_HAVE_RPC y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MDEV_CONF y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MDEV_RENAME y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MDEV_RENAME_REGEXP y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MDEV_EXEC y
        config_set package/busybox/busybox-1.11.x.config CONFIG_FEATURE_MDEV_LOAD_FIRMWARE y
        config_set package/busybox/busybox-1.11.x.config CONFIG_OPENVT y
        config_set package/busybox/busybox-1.11.x.config CONFIG_CTTYHACK y
    fi
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
    #logicTrue $(profile_get_key aoetools) && require aoetools
    if logicTrue $(profile_get_key luks)
    then
        print_info 1 'BUILDROOT (Packages): > Enabling luks cryptsetup...'
        config_set .config BR2_PACKAGE_CRYPTSETUP y
    fi

    if logicTrue $(profile_get_key open-iscsi)
    then
        print_info 1 'BUILDROOT (Packages): > Enabling openiscsi iscsistart...'
        config_set .config BR2_PACKAGE_OPENISCSI_ISCSISTART y
    fi
    if logicTrue $(profile_get_key aoetools)
    then
        print_info 1 'BUILDROOT (Packages): > Enabling aoetools...'
        config_set .config BR2_PACKAGE_AOETOOLS y
    fi

    # Clean out destination target so we only get the packages we want
    rm -rf "project_build_$(profile_get_key utils-arch)/uclibc/root"

    # Buildroot gets mad if these directory doesnt exist... 
    mkdir -p "project_build_$(profile_get_key utils-arch)/uclibc/root/usr/sbin"
    mkdir -p "project_build_$(profile_get_key utils-arch)/uclibc/root/usr/lib"
    mkdir -p "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/init.d"

    for i in 0 1 2 3 4 5
    do
    	echo "etherd!e$i.0 0:0 777 >etherd/e$i.0" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
    	for j in 1 2 3 4 5 6 7 8 
	do
    	echo "etherd!e$i.0p$j 0:0 777 >etherd/e$i.0p$j" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
	done
    done
    echo "discover 0:0 777 >etherd/" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
    echo "revalidate 0:0 777 >etherd/" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
    echo "flush 0:0 777 >etherd/" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
    echo "err 0:0 777 >etherd/" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"
    echo "interfaces 0:0 777 >etherd/" >> "project_build_$(profile_get_key utils-arch)/uclibc/root/etc/mdev.conf"

    # Make this directory for aoe support
    mkdir -p "project_build_$(profile_get_key utils-arch)/uclibc/root/dev/etherd"

	
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
