#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_19 {
	echo -e "\n19. Do the \"Time-\" and \"MD5R\" control strings work as expected?"
}

fn_make_files_1
fn_test_19
