#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_1 {
	echo -e "\n1.  Given a directory with an additional directory inside, will stat_watch.pl capture details for files within both of these directories"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/(subdir/)?123\.php' -- " ) -ne 3 ]]; then
		fn_fail "1.1"
	fi
	fn_pass "1.1"
}

function fn_test_2 {
	echo -e "\n2.  Will stat_watch.pl recognize file names with special characters, quotes, or new lines"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123('|\"|\?|!)456\.php' -- " ) -ne 4 ]]; then
		fn_fail "2.1"
	fi
	fn_pass "2.1"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123_mlfn_[0-9]+456\.php' -- " ) -ne 1 ]]; then
		fn_fail "2.2"
	fi
	fn_pass "2.2"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123(ᡘ|Ͼ)456\.php' -- " ) -ne 2 ]]; then
		fn_fail "2.3"
	fi
	fn_pass "2.3"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123""$( echo -e "\0010" )""456\.html" ) -ne 1 ]]; then
		fn_fail "2.4"
	fi
	fn_pass "2.4"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "12456\.html" ) -ne 0 ]]; then
		fn_fail "2.5"
	fi
	fn_pass "2.5"
}

function fn_test_3 {
	echo -e "\n3.  Will stat_watch.pl recognize changes to files in \"--diff\" mode"
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A10 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "testing/(subdir/)?123" ) -ne 9 ]]; then
		fn_fail "3.1"
	fi
	fn_pass "3.1"
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "3.2"
	fi
	fn_pass "3.2"
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "3.3"
	fi
	fn_pass "3.3"
}

function fn_test_4 {
	echo -e "\n4.  If the report files are given in the wrong order, will stat_watch.pl sort them out? Will it avoid sorting them if they have the \"--before\" and \"--after\" flags"
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.1"
	fi
	fn_pass "4.1"
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.2"
	fi
	fn_pass "4.2"
	if [[ $( "$f_STAT_WATCH" --diff --before "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --after "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.3"
	fi
	fn_pass "4.3"
	if [[ $( "$f_STAT_WATCH" --diff --before "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --after "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.4"
	fi
	fn_pass "4.4"
}

fn_make_files_1
fn_test_1
fn_test_2
fn_test_3
fn_test_4
