#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_15 {
	echo -e "\n15. Does ignoring work as anticipated (\"--ignore\" flag, bare string in the job file, \"*\" and \"R\" control strings)"
}

fn_make_files_1
fn_test_15
