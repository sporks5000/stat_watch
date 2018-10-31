#! /bin/bash

function fn_test_20 {
	echo "20. If a directory is not readable or is not executable (or both) how does this impact Stat Watch?"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_20 "$@"
