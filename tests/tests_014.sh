#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_14 {
	echo -e "\n14. Is the \"--ignore-on-record\" functionality working as anticipated?"
}

fn_make_files_1
fn_test_14
