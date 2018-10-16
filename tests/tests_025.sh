#! /bin/bash

function fn_test_25 {
	echo "25. Test to verify that \"--run\" is running jobs correctly, with or without an assumption, either with the job name or the file"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
}

fn_test_25 "$@"
