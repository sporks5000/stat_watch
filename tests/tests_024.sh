#! /bin/bash

function fn_test_24 {
	echo "24. Test to verify that \"--create\" is creating jobs correctly"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
}

fn_test_24 "$@"
