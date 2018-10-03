#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_24 {
	echo -e "\n24. test to verify that \"--create\" is creating jobs correctly"
}

fn_make_files_1
fn_test_24
