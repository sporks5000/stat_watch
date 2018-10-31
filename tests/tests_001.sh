#! /bin/bash

function fn_test_1 {
	echo "1.  Given a directory with an additional directory inside, will stat_watch.pl capture details for files within both of these directories"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing | egrep -c "testing/(subdir/)?123\.php' -- " ) -ne 3 ]]; then
		fn_fail "1.1"
	fi
	fn_pass "1.1"
}

fn_test_1 "$@"
