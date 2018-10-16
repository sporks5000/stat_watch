#! /bin/bash

function fn_test_16 {
	echo "16. Are configuration files being created, updated, and read from correctly?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
}

fn_test_16 "$@"
