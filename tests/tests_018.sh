#! /bin/bash

function fn_test_18 {
	echo "18. Do the \"I\" and \"Include\" control strings work as expected?"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_18 "$@"
