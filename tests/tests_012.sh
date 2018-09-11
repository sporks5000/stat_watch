#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_12 {
	echo -e "\n12. Is backup pruning working as anticipated?"
}

fn_make_files_1
fn_test_12
