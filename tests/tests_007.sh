#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_7 {
	echo -e "\n7.  Does gathering md5 sums work?"
	fn_md5_modules
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --md5
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 13 ]]; then
		fn_fail "7.1"
	fi
	fn_pass "7.1"
	"$f_STAT_WATCH" "$d_STATWATCH_TESTS_WORKING"/testing -i <( echo "MD5 $d_STATWATCH_TESTS_WORKING/testing/123'456.php" ) --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.2"
	fi
	fn_pass "7.2"
	if [[ $( egrep "testing/123'456\.php" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.3"
	fi
	fn_pass "7.3"
	"$f_STAT_WATCH" "$d_STATWATCH_TESTS_WORKING"/testing -i <( echo "MD5R \.txt$" ) --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 2 ]]; then
		fn_fail "7.4"
	fi
	fn_pass "7.4"
	if [[ $EUID -ne 0 ]]; then
		echo -e "\e[33m""Test 7.5 SKIPPED""\e[0m"" - must be run as root"
		echo -e "\e[33m""Test 7.6 SKIPPED""\e[0m"" - must be run as root"
		echo -e "\e[33m""Test 7.7 SKIPPED""\e[0m"" - must be run as root"
	else
		### Test getting md5sums of files marked as unreadable
		fn_remove_files
		fn_make_files_1
		chmod 000 "$d_STATWATCH_TESTS_WORKING"/testing/123.php
		"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --md5
		if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 13 ]]; then
			fn_fail "7.5"
		fi
		fn_pass "7.5"
		fn_make_user
		sudo -u "$v_USER" "$d_USER_STATWATCH"/stat_watch.pl --record "$d_USER_STATWATCH"/tests/working/testing --output "$d_USER_STATWATCH"/tests/working/testing2/report1.txt --md5
		if [[ $( cat "$d_USER_STATWATCH"/tests/working/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 12 ]]; then
			fn_fail "7.6"
		fi
		fn_pass "7.6"
		if [[ $( egrep -c "[-]-\s*$" "$d_USER_STATWATCH"/tests/working/testing2/report1.txt ) -gt 0 ]]; then
			### If any of the lines end in "--", things will likely get parsed wrong
			fn_fail "7.7"
		fi
		fn_pass "7.7"
		fn_unmake_user
	fi
}

fn_make_files_1
fn_test_7
