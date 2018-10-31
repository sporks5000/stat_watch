#! /bin/bash

function fn_test_7 {
	echo "7.  Does gathering md5 sums work?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_PROGRAM_TESTS"/tests_include.shf
	fn_make_files_1

	### Test recording with md5's
	fn_md5_modules
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt --md5
	if [[ $( cat "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 15 ]]; then
		fn_fail "7.1"
	fi
	fn_pass "7.1"

	### Test if we've only specified one file to get an md5 for
	"$f_STAT_WATCH" --config "$f_CONF" "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "MD5 $d_PROGRAM_TESTS_WORKING/testing/123'456.php" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( cat "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.2.1"
	fi
	### And make sure that we got the right file
	if [[ $( egrep "testing/123'456\.php" "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.2.2"
	fi
	fn_pass "7.2"

	### Test regular expressions
	"$f_STAT_WATCH" --config "$f_CONF" "$d_PROGRAM_TESTS_WORKING"/testing -i <( echo "MD5R \.txt$" ) --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt
	if [[ $( cat "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 2 ]]; then
		fn_fail "7.3"
	fi
	fn_pass "7.3"

	if [[ $EUID -ne 0 ]]; then
		echo -e "\e[33m""Test 7.4 SKIPPED""\e[0m"" - must be run as root"
		echo -e "\e[33m""Test 7.5 SKIPPED""\e[0m"" - must be run as root"
	else
		### Test getting md5sums of files marked as unreadable
		fn_remove_files
		fn_make_files_1
		chmod 000 "$d_PROGRAM_TESTS_WORKING"/testing/123.php
		"$f_STAT_WATCH" --config "$f_CONF" --record "$d_PROGRAM_TESTS_WORKING"/testing --output "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt --md5
		if [[ $( cat "$d_PROGRAM_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 14 ]]; then
			fn_fail "7.4"
		fi
		fn_pass "7.4"

		### Test again, but this time not with the root user
		fn_make_user
		sudo -u "$v_USER" "$d_USER_STATWATCH"/stat_watch_wrap.sh --record --locate "$d_USER_STATWATCH"/tests/working/testing --output "$d_USER_STATWATCH"/tests/working/testing2/report1.txt --md5
		if [[ $( cat "$d_USER_STATWATCH"/tests/working/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 13 ]]; then
			fn_fail "7.5.1"
		fi
		### And verify that not getting it doesn't throw the formatting of the report file off
		if [[ $( egrep -c "[-]-\s*$" "$d_USER_STATWATCH"/tests/working/testing2/report1.txt ) -gt 0 ]]; then
			### If any of the lines end in "--", things will likely get parsed wrong
			fn_fail "7.5.2"
		fi
		fn_pass "7.5"
		fn_unmake_user
	fi
}

fn_test_7 "$@"
