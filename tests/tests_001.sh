#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_1 {
	echo -e "\n1.  Given a directory with an additional directory inside, will stat_watch.pl capture details for files within both of these directories"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/(subdir/)?123\.php' -- " ) -ne 3 ]]; then
		fn_fail "1.1"
	fi
	fn_pass "1.1"
}

fn_make_files_1
fn_test_1
