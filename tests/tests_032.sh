#! /bin/bash

function fn_test_32 {
	echo "32. Test to verify that all aspects of \"--run\" are working correctly"
	echo -e "\e[35mNOT YET IMPLIMENTED\e[00m"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Is locking to prevent multiple concurrent jobs working as expected?
	### Is pruning occurring when expected?
	### Is db_watch being launched when expected?
	### Is job expiration working as expected?
}

fn_test_32 "$@"
