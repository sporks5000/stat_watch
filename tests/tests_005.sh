#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_5 {
	echo -e "\n5.  Will stat_watch.pl raccurately replace paths using the \"--as-dir\" flag?"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "Processing: '/home'" ) -ne 1 ]]; then
		fn_fail "5.1"
	fi
	fn_pass "5.1"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home' -- " ) -ne 1 ]]; then
		fn_fail "5.2"
	fi
	fn_pass "5.2"
	if [[ $( "$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --as-dir /home | egrep -c "^'/home" ) -ne 16 ]]; then
		fn_fail "5.3"
	fi
	fn_pass "5.3"
}

function fn_test_6 {
	echo -e "\n6.  Does the \"--backup\" flag work as expected"
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "6.1"
	fi
	fn_pass "6.1"
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 1 ]]; then
		### There were no changes to this file, so a second backup should not have been made
		fn_fail "6.2"
	fi
	fn_pass "6.2"
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "6.3"
	fi
	fn_pass "6.3"
	fn_remove_files
	fn_make_files_1
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backupr '\.php$' --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 8 ]]; then
		fn_fail "6.4"
	fi
	fn_pass "6.4"
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 && $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/subdir | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "6.5"
	fi
	fn_pass "6.5"
	sleep 1.1
	echo "1235" > "$d_STATWATCH_TESTS_WORKING/testing/123?456.php"
	echo "1235" > "$d_STATWATCH_TESTS_WORKING/testing/123!456.php"
	echo "1235" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backupr '\.php$' --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 11 ]]; then
		fn_fail "6.6"
	fi
	fn_pass "6.6"
}

fn_make_files_1
fn_test_5
fn_test_6
