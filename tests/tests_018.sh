#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_18 {
	echo -e "\n18. Do the \"I\" and \"Include\" control strings work as expected?"
}

fn_make_files_1
fn_test_18
