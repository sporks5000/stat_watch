#! /bin/bash

function fn_test_5 {
	echo "5.  Will stat_watch.pl accurately replace paths using the \"--as-dir\" flag?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Make sure that it is accurately labeling the report as saying that it's looking in the changed directory
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "Processing: '/home'" ) -ne 1 ]]; then
		fn_fail "5.1"
	fi
	fn_pass "5.1"

	### Make sure that it's accurately labeling the root directory for the search as the new directory
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home' -- " ) -ne 1 ]]; then
		fn_fail "5.2"
	fi
	fn_pass "5.2"

	### Make sure that all files are being accurately labeled as existing in the new directory
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home" ) -ne 17 ]]; then
		fn_fail "5.3"
	fi
	fn_pass "5.3"
}

fn_test_5 "$@"
