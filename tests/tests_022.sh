#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_22 {
	echo -e "\n22. test to ensure that --backup-file is working as anticipated (including \"--hold\" and \"--comment\" functionality)"
}

fn_make_files_1
fn_test_22
