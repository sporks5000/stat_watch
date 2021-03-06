#! /bin/bash

function fn_test_8 {
	echo "8.  Is max-depth working as expected?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1

	sleep 1.1
	### hen given a max depth, make sure that it ends up in the report
	"$f_STAT_WATCH" --config "$f_CONF" "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "Max-depth 0" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( egrep -c "^Maximum depth reached at" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 1 ]]; then
		fn_fail "8.1.1"
	fi
	### And that directories below that max depth do NOT end up in the report
	if [[ $( egrep -c "subdir/" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt ) -ne 0 ]]; then
		fn_fail "8.1.2"
	fi
	fn_pass "8.1"

	### The "--diff" output should only include instances where we've hit max depth if at least one change has been detected
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "Max-depth 0" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt | egrep -c "DIRECTORIES TOO DEEP TO PROCESS" ) -ne 0 ]]; then
		fn_fail "8.2"
	fi
	fn_pass "8.2"

	### But once we've changed something, it should be in the "--diff" output
	sleep 1.1
	mkdir -p "$d_PROGRAM_TESTS_WORKING/testing/subdir2"
	"$f_STAT_WATCH" --config "$f_CONF" "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "Max-depth 0" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --diff "$d_PROGRAM_TESTS_WORKING"/testing2/report2.txt "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | egrep -A2 "DIRECTORIES TOO DEEP TO PROCESS" | egrep -c "testing/subdir" ) -ne 2 ]]; then
		fn_fail "8.3"
	fi
	fn_pass "8.3"
}

fn_test_8 "$@"
