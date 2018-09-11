#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_17 {
	echo -e "\n17. Do the \"--no-ctime\" and \"--no-partial-seconds\" flags work as expected?"
}

fn_make_files_1
fn_test_17
