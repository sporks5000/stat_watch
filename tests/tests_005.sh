#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_5 {
	echo -e "\n5.  Will stat_watch.pl raccurately replace paths using the \"--as-dir\" flag?"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "Processing: '/home'" ) -ne 1 ]]; then
		fn_fail "5.1"
	fi
	fn_pass "5.1"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home' -- " ) -ne 1 ]]; then
		fn_fail "5.2"
	fi
	fn_pass "5.2"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home" ) -ne 16 ]]; then
		fn_fail "5.3"
	fi
	fn_pass "5.3"
}

fn_make_files_1
fn_test_5
