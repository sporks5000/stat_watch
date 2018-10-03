#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_13 {
	echo -e "\n13. Is logging working as anticipated?"
	### Logging is controlled with the control string "Log", which populates the variable "$f_log".
	### Logging is handled by the subroutine fn_log
	### By default, no logging is done; there is no command line flag to set logging
}

fn_make_files_1
fn_test_13

