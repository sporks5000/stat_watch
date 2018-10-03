#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_14 {
	echo -e "\n14. Is the \"--ignore-on-record\" functionality working as anticipated?"
	### When in "--record" mode, by default, only directories are checked to see if they match the ignore rules specified, "--ignore-on-record" overrieds this and checks everything
	### Using the "--ignore-on-record" flag sets the variable "$b_ignore_on_record"
	### If "$b_ignore_on_record" is true, every file will be run past the function "fn_check_file" while being processed by the function "fn_stat_watch"
}

fn_make_files_1
fn_test_14
