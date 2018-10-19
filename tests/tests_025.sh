#! /bin/bash

function fn_test_25 {
	echo "25. Test to verify that \"--run\" is running jobs correctly, with or without an assumption, either with the job name or the file"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_25 "$@"
