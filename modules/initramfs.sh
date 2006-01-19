

if logicTrue $(profile_get_key install)
then
	require initramfs_install
else
	require initramfs_create
fi

initramfs::() { true; }
