#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_25 {
	echo -e "\n25. test to verify that \"--run\" is running jobs correctly, with or without an assumption, either with the job name or the file"
}

fn_make_files_1
fn_test_25
