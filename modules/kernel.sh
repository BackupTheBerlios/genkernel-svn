if logicTrue $(profile_get_key install)
then
	require kernel_install
	require kernel_modules_install
else
	require kernel_compile
	require kernel_modules_compile
fi

kernel::() { true; }
