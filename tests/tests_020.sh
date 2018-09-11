#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_20 {
	echo -e "\n20. If a directory is not readable or is not executable (or both) how does the impact Stat Watch?"
}

fn_make_files_1
fn_test_20
