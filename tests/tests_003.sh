#! /bin/bash

function fn_test_3 {
	echo "3.  Will stat_watch.pl recognize changes to files in \"--diff\" mode"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt

	### Test files with change to time
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A10 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "testing/(subdir/)?123" ) -ne 9 ]]; then
		fn_fail "3.1"
	fi
	fn_pass "3.1"

	### Test files that are new
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "3.2"
	fi
	fn_pass "3.2"

	### Test files that have been removed
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "3.3"
	fi
	fn_pass "3.3"
}

fn_test_3 "$@"
