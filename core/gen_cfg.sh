#!/bin/bash

declare -a __CONFIG__REG__S # Source
declare -a __CONFIG__REG__D # Data
declare -a __CONFIG__REG__M # Missing Message

cfg_register_read() {
	
	if [ ${#__CONFIG__REG__D[@]} > 0 ]
	then
		print_warning 1 "YOU HAVE THE FOLLOWING KERNEL CONFIG OPTIONS ${BOLD}DISABLED"
		echo
	fi

	for (( n = 0 ; n < ${#__CONFIG__REG__D[@]}; ++n )) ; do
		if kernel_config_is_not_set ${__CONFIG__REG__D[${n}]}
		then
			if [ "${__CONFIG__REG__M[${n}]}" != "" ]
			then
				print_warning 1 "CONFIG_${__CONFIG__REG__D[${n}]}: ${__CONFIG__REG__M[${n}]} "
			else
				print_warning 1 "CONFIG_${__CONFIG__REG__D[${n}]} is missing.  You may have problems booting your system...."
			fi
		fi
	done
}

cfg_register_lookup() {
	local data

	for (( n = 0 ; n < ${#__CONFIG__REG__D[@]}; ++n )) ; do
		data=${__CONFIG__REG__D[${n}]}
		[ "$1" = "${data}" ] && return 0
	done
	return 1
}

cfg_register() {
    local myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	if ! cfg_register_lookup $1
	then
		__CONFIG__REG__S[${#__CONFIG__REG__S[@]}]="${myCaller}"
		__CONFIG__REG__D[${#__CONFIG__REG__D[@]}]="${1}"
		__CONFIG__REG__M[${#__CONFIG__REG__M[@]}]="${2}"
	fi
}

