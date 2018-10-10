#! /bin/bash

function fn_test_15 {
	echo -e "\e[35mThere is no test 15\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_15 "$@"
