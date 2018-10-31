#! /bin/bash

function fn_test_34 {
	echo "34. Does the \"--report-details\" flag work as anticipated?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1

	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt

	### Basic test
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --rd "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -c "Processing of '.*' started at" ) -ne 1 ]]; then
		fn_fail "34.1"
	fi
	fn_pass "34.1"

	### If we specify a file, will it output stats regarding that file
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --rd "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing/123.php | egrep -c "^  FILE" ) -ne 1 ]]; then
		fn_fail "34.2"
	fi
	fn_pass "34.2"

	### If we specify the report and the file in the opposite order, does it work?
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --rd --file "$d_PROGRAM_TESTS_WORKING"/testing/123.php --report "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -c "^  FILE" ) -ne 1 ]]; then
		fn_fail "34.3"
	fi
	fn_pass "34.3"

	### More than one file
	### If we specify the report and the file in the opposite order, does it work?
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --report-details --file "$d_PROGRAM_TESTS_WORKING"/testing/123.php --report "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing/123Ͼ456.php | egrep -c "^  FILE" ) -ne 2 ]]; then
		fn_fail "34.4"
	fi
	fn_pass "34.4"
}

fn_test_34 "$@"
