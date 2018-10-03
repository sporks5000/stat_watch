#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_21 {
	echo -e "\n21. If a directory is included specifically but otherwise would be ignored, is it processed as anticipated?"
	### All directories listed at the command line or with the control string "I" are added to the global array "@v_dirs"
		### Note: "@v_dirs" is used elsewhere in the script in local scopes. We are only concerned about the global here
	### Every time a new listed directory is processed the subroutine "fn_check_strings" is run against it to verify that we remove any rules that would exclude it
	### "fn_check_strings" checks the directory against "@v_ignore", "@v_rignore", and "@v_star_ignore" to create "@v_temp_ignore", "@v_temp_rignore", and "@v_temp_star_ignore"
	### The three temp arrays are used in the subroutine "fn_check_file" to verify that files don't match any of these
}

fn_make_files_1
fn_test_21
