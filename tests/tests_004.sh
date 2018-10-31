#! /bin/bash

function fn_test_4 {
	echo "4.  If the report files are given in the wrong order, will stat_watch.pl sort them out? Will it avoid sorting them if they have the \"--before\" and \"--after\" flags"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt

	### Check the output when giving the files in the incorrect order
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.1"
	fi
	fn_pass "4.1"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.2"
	fi
	fn_pass "4.2"

	### Check the output when giing the files in the incorrect order, but with flags to show that you want them that way
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff --before "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt --after "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.3"
	fi
	fn_pass "4.3"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff --before "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt --after "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.4"
	fi
	fn_pass "4.4"
}

fn_test_4 "$@"
