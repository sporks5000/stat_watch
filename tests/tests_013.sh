#! /bin/bash

function fn_test_13 {
	echo "13. Is logging working as anticipated?"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	### Logging is controlled with the control string "Log", which populates the variable "$f_log".
	### Logging is handled by the subroutine fn_log
	### By default, no logging is done; there is no command line flag to set logging

}

fn_test_13 "$@"

