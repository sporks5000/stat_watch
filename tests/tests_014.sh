#! /bin/bash

function fn_test_14_1 {
	echo "14.1 Does ignoring work as anticipated (\"--ignore\" flag, bare string in the job file, \"*\" and \"R\" control strings) with \"--record\""
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	fn_make_files_2

	### Verify that all of the initial files we care about are there
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 10 ]]; then
		fn_fail "14.1.1"
	fi
	fn_pass "14.1.1"

	### Test ignoring with the "--ignore" flag
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --ignore "$d_PROGRAM_TESTS_WORKING"/testing/subdir2 --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 6 ]]; then
		fn_fail "14.1.2"
	fi
	fn_pass "14.1.2"

	### The "--ignore" flag should only match exact file names
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --ignore "$d_PROGRAM_TESTS_WORKING"/testing/sub --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 10 ]]; then
		fn_fail "14.1.3.1"
	fi
	### Without "--ignore-on-record", that file actually should not have been ignored
	if [[ $( egrep -c "sub' --" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 1 ]]; then
		fn_fail "14.1.3.2"
	fi
	fn_pass "14.1.3"

	### Verify that bare filenames in a job file work the same
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/subdir2 ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 6 ]]; then
		fn_fail "14.1.4"
	fi
	fn_pass "14.1.4"

	### And again
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/sub ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 10 ]]; then
		fn_fail "14.1.5.1"
	fi
	### Without "--ignore-on-record", that file actually should not have been ignored
	if [[ $( egrep -c "sub' --" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 1 ]]; then
		fn_fail "14.1.5.2"
	fi
	fn_pass "14.1.5"

	### "*" should match any file whose full path matches that string
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/subdir ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 4 ]]; then
		fn_fail "14.1.6"
	fi
	fn_pass "14.1.6"

	### And again
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/sub ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 4 ]]; then
		fn_fail "14.1.7.1"
	fi
	### Without "--ignore-on-record", that file actually should not have been ignored
	if [[ $( egrep -c "sub' --" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 1 ]]; then
		fn_fail "14.1.7.2"
	fi
	fn_pass "14.1.7"

	### The "R" string should ignore anything that matches regex
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "R ing/subd"; echo "R \n" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 2 ]]; then
		fn_fail "14.1.8.1"
	fi
	if [[ $( egrep "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -c "mlfn" ) -ne 2 ]]; then
		fn_fail "14.1.8.2"
	fi
	fn_pass "14.1.8"
}

function fn_test_14_2 {
	echo "14.2 Does the \"--ignore-on-record\" flag work as anticipated?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	fn_make_files_2

	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --ignore "$d_PROGRAM_TESTS_WORKING"/testing/sub --ignore-on-record --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir[234]|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 10 ]]; then
		fn_fail "14.2.1.1"
	fi
	### Without "--ignore-on-record", that file actually should not have been ignored
	if [[ $( egrep -c "sub' --" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 0 ]]; then
		fn_fail "14.2.1.2"
	fi
	fn_pass "14.2.1"

	### Test "*"
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/sub ) --ignore-on-record --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "sub|mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 4 ]]; then
		fn_fail "14.2.2"
	fi
	fn_pass "14.2.2"

	### The "R" string should ignore anything that matches regex
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "R ing/subdir[0-9]"; echo "R \n" ) --ignore-on-record --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "subdir" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 9 ]]; then
		fn_fail "14.2.3.1"
	fi
	if [[ $( egrep -c "mlfn" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 0 ]]; then
		fn_fail "14.2.3.2"
	fi
	fn_pass "14.2.3"
}

function fn_test_14_3 {
	echo "14.3 Does ignoring work as anticipated (\"--ignore\" flag, bare string in the job file, \"*\" and \"R\" control strings) with \"--diff\""
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1
	fn_make_files_2

	### Set things up
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	fn_change_files_2
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt

	### Test with "--ignore"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt --ignore "$d_PROGRAM_TESTS_WORKING"/testing/123.php | egrep -c "FILES THAT WERE REMOVED" ) -ne 1 ]]; then
		fn_fail "14.3.1.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt --ignore "$d_PROGRAM_TESTS_WORKING"/testing/123.php | egrep -A2 "FILES THAT WERE REMOVED" | egrep -c "testing/123.php" ) -ne 0 ]]; then
		fn_fail "14.3.1.2"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt --ignore "$d_PROGRAM_TESTS_WORKING"/testing/123.php --ignore "$d_PROGRAM_TESTS_WORKING"/testing/"$v_ANGRY"/123.png  | egrep -c "FILES THAT WERE REMOVED" ) -ne 0 ]]; then
		fn_fail "14.3.1.3"
	fi
	fn_pass "14.3.1"

	### Test with the bare ignore string
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/123.php ) | egrep -c "FILES THAT WERE REMOVED" ) -ne 1 ]]; then
		fn_fail "14.3.2.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/123.php ) | egrep -A2 "FILES THAT WERE REMOVED" | egrep -c "testing/123.php" ) -ne 0 ]]; then
		fn_fail "14.3.2.2"
	fi
	fn_pass "14.3.2"

	### Verify that it's not inappropriatey removing files
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/sub ) | egrep -c "testing/sub" ) -lt 5 ]]; then
		fn_fail "14.3.3.1"
	fi
	### Without "--ignore-on-record", that file actually should not have been ignored
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "$d_PROGRAM_TESTS_WORKING"/testing/sub ) | egrep -c "testing/sub'( \(Also listed above\))?" ) -ne 0 ]]; then
		fn_fail "14.3.3.2"
	fi
	fn_pass "14.3.3"

	### Verify that "*" is working corectly
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/subdi ) | egrep -c "sub" ) -ne 3 ]]; then
		fn_fail "14.3.4"
	fi
	fn_pass "14.3.4"

	### And again
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/sub ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "* $d_PROGRAM_TESTS_WORKING"/testing/sub ) | egrep -c "sub" ) -ne 0 ]]; then
		fn_fail "14.3.5"
	fi
	fn_pass "14.3.5"

	### The "R" string should ignore anything that matches regex
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "R ing/subd"; echo "R \n" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "R ing/subdir[0-9]"; echo "R \n" ) | fgrep -c "$'\n'" ) -ne 0 ]]; then
		fn_fail "14.3.6.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "R ing/subdir[0-9]"; echo "R \n" ) | egrep -c "subdir[0-9]" ) -ne 4 ]]; then
		fn_fail "14.3.6.2"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt -i <( echo "R ing/subdir[0-9]"; echo "R \n" ) | egrep -c "testing/subdir[0-9]" ) -ne 0 ]]; then
		fn_fail "14.3.6.3"
	fi
	fn_pass "14.3.6"
}

fn_test_14_1 "$@"
fn_test_14_2 "$@"
fn_test_14_3 "$@"
