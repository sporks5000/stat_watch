#! /bin/bash

function fn_test_31 {
	echo "31. Test the functionality of \"--compare\""
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

}

fn_test_31 "$@"
