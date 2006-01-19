#!/bin/bash

declare -a __MESSAGES__REG__S # Source
declare -a __MESSAGES__REG__D # Data

messages_register_read() {
	for (( n = 0 ; n < ${#__MESSAGES__REG__D[@]}; ++n )) ; do
		print_info 1 "${__MESSAGES__REG__D[${n}]}"
	done
}

messages_register_lookup() {
	local source data

	for (( n = 0 ; n < ${#__MESSAGES__REG__D[@]}; ++n )) ; do
		source=${__MESSAGES__REG__S[${n}]}
		data=${__MESSAGES__REG__D[${n}]}
		[ "$1" = "${data}" ] && echo "${source}" && return
	done
}

messages_register() {
	local myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	# Check something does not already provide this message,
	# unless the module is the same in which case ignore the request.
	# If no clashes are found commit the change.

	#myCheck=$(messages_register_lookup $1)
	#if [ -n "${myCheck}" -a "${myCheck}" != "${myCaller}" ]
	#then
	#		die "Conflicting message provide ($1 in ${myCaller} against $1 in ${myCheck})..."
	#else
	#		echo "registering $1 to $myCaller"	
	__MESSAGES__REG__S[${#__MESSAGES__REG__S[@]}]="${myCaller}"
	__MESSAGES__REG__D[${#__MESSAGES__REG__D[@]}]="${1}"
	#fi
}

