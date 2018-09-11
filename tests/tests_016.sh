#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_16 {
	echo -e "\n16. Does the \"--no-check-retention\" flag work as expected?"
}

fn_make_files_1
fn_test_16
