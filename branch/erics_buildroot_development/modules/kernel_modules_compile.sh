require kernel_config
kernel_modules_compile::()
{
    cd $(profile_get_key kbuild-output)
    if [ -d "${CACHE_DIR}/kernel-modules-compile-output" ]
    then
        CACHED_KCONFIG_MD5SUM=$(cat ${CACHE_DIR}/kernel-modules-compile-output/kernel-config-${KV_FULL}.md5sum)
        KCONFIG_MD5SUM=$(cat .config|grep ^CONFIG|sort|md5sum |awk '{print $1}')
    else
        CACHED_KCONFIG_MD5SUM=1
        KCONFIG_MD5SUM=0
    fi
    if [ "${CACHED_KCONFIG_MD5SUM}" != "${KCONFIG_MD5SUM}" ]
    then
        if kernel_config_is_not_set "MODULES"
        then
            print_info 1 ">> Modules not enabled in .config... skipping modules compile"
        else
	    rm -rf ${CACHE_DIR}/kernel-modules-compile-output/
	    mkdir -p ${CACHE_DIR}/kernel-modules-compile-output/
            setup_kernel_args

            # make the modules
            print_info 1 '>> Preparing to compile kernel modules ...'
            compile_generic ${KERNEL_ARGS} modules_prepare

            print_info 1 '>> Compiling kernel modules ...'
            compile_generic ${KERNEL_ARGS} modules

            compile_generic ${KERNEL_ARGS} INSTALL_MOD_PATH=${CACHE_DIR}/kernel-modules-compile-output modules_install
            cat .config|grep ^CONFIG|sort|md5sum |awk '{print $1}' > ${CACHE_DIR}/kernel-modules-compile-output/kernel-config-${KV_FULL}.md5sum
        fi
    else
        print_info 1 '>> Kernel .config unchanged using cached kernel modules'
    fi
    cd ${CACHE_DIR}/kernel-modules-compile-output
    genkernel_generate_package "kernel-modules-${KV_FULL}" "."
}
