#! /bin/bash

function fn_test_33 {
	echo "33. Test basic functionality of db_watch"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1

	### How am I going to do this?
}

fn_test_33 "$@"
