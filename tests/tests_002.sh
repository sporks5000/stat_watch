#! /bin/bash

function fn_test_2 {
	echo "2.  Will stat_watch.pl recognize file names with special characters, quotes, or new lines"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123('|\"|\?|!)456\.php' -- " ) -ne 4 ]]; then
		fn_fail "2.1"
	fi
	fn_pass "2.1"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123_mlfn_[0-9]+456\.php' -- " ) -ne 1 ]]; then
		fn_fail "2.2"
	fi
	fn_pass "2.2"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/123(ᡘ|Ͼ)456\.php' -- " ) -ne 2 ]]; then
		fn_fail "2.3"
	fi
	fn_pass "2.3"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123""$( echo -e "\0010" )""456\.html" ) -ne 1 ]]; then
		fn_fail "2.4"
	fi
	fn_pass "2.4"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "12456\.html" ) -ne 0 ]]; then
		fn_fail "2.5"
	fi
	fn_pass "2.5"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "testing/subdir/123💩456.php' -- " ) -ne 1 ]]; then
		fn_fail "2.6"
	fi
	fn_pass "2.6"
}

fn_test_2 "$@"
