#! /bin/bash

function fn_test_17 {
	echo "17. Do the \"--no-ctime\" and \"--no-partial-seconds\" flags work as expected?"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_17 "$@"
