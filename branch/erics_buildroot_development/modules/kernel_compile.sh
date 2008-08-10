require kernel_config
logicTrue $(internal_initramfs) && require initramfs_create

kernel_compile::()
{
    setup_kernel_args
    cd $(profile_get_key kbuild-output)
    if [ -d "${CACHE_DIR}/kernel-compile-output" ]
    then
        CACHED_KCONFIG_MD5SUM=$(cat ${CACHE_DIR}/kernel-compile-output/kernel.md5sum)
        KCONFIG_MD5SUM=$(cat .config|grep ^CONFIG|sort|md5sum |awk '{print $1}')
    else
        CACHED_KCONFIG_MD5SUM=1
        KCONFIG_MD5SUM=0
    fi
    echo ${CACHED_KCONFIG_MD5SUM}
    echo ${KCONFIG_MD5SUM}
    if [ "${CACHED_KCONFIG_MD5SUM}" != "${KCONFIG_MD5SUM}" ]
    then
        # Compile the kernel image
        print_info 1 '>> Compiling kernel ...'
        compile_generic ${KERNEL_ARGS} $(profile_get_key kernel-make-directive)
        RES=$?
        rm -rf "${CACHE_DIR}/kernel-compile-output" > /dev/null
        mkdir -p ${CACHE_DIR}/kernel-compile-output
        install -D "$(profile_get_key kernel-binary)" "${CACHE_DIR}/kernel-compile-output/$(profile_get_key kernel-binary)"
        cat .config|grep ^CONFIG|sort|md5sum |awk '{print $1}' > ${CACHE_DIR}/kernel-compile-output/kernel.md5sum
        cp "System.map" "${CACHE_DIR}/kernel-compile-output"
        cp .config "${CACHE_DIR}/kernel-compile-output"
        if [ "$RES" == "0" ]
        then
            print_info 1 ''
            print_info 1 "Kernel compiled successfully!"
            print_info 1 ''
        else
            print_info 1 'Do NOT report kernel bugs as genkernel bugs unless your bug'
            print_info 1 'is about the default genkernel configuration...'
            print_info 1 ''
            print_info 1 'Make sure you have the latest genkernel before reporting bugs.'
            print_info 1 ''
            die "Kernel Compilation failed.  Check your debuglog for details"
        fi
    else
        print_info 1 '>> Kernel .config unchanged using cached kernel'
    fi

    cd ${CACHE_DIR}/kernel-compile-output
    genkernel_generate_package "kernel-${KV_FULL}" "."
}
