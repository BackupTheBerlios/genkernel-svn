require @pkg_e2fsprogs-${E2FSPROGS_VER}-blkid:null:e2fsprogs_compile

e2fsprogs::()
{
    cd ${TEMP}
    genkernel_extract_package "e2fsprogs-${E2FSPROGS_VER}-blkid"
    
	# generate CPIO
    rm -rf ${TEMP}/e2fsprogs-cpiogen
    mkdir -p ${TEMP}/e2fsprogs-cpiogen/bin
    mv "${TEMP}/blkid" "${TEMP}/e2fsprogs-cpiogen/bin/blkid"
    cd e2fsprogs-cpiogen
    genkernel_generate_cpio_files "e2fsprogs-${E2FSPROGS_VER}-blkid" .
    initramfs_register_cpio "e2fsprogs-${E2FSPROGS_VER}-blkid"
}

