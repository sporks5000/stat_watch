#! /bin/bash

function fn_test_19 {
	echo "19. Do the \"Time-\" and \"MD5R\" control strings work as expected?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
}

fn_test_19 "$@"
