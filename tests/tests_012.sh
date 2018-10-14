#! /bin/bash

### There are two ways that backups are pruned: when the "--prune" flag is used, and when a backup of a file is made during "--diff" (assuming "--no-check-retention" was not used)
### Backups are pruned within the "fn_check_retention" subroutine
### When backups are pruned is controled by the $v_retention_max_copies variable and the $v_retention_min_days variable
### $v_retention_max_copies defaults to 4 and is set by the "BackupMC" control string and the "--backup-mc" flag
### $v_retention_min_days defaults to 7 and is set by the "BackupMD" control string and the "--backup-md" flag
### The desired behavior is: If there are more than $v_retention_max_copies backups of a file, all of the copies older than $v_retention_min_days days will be removed
	### Thus if $v_retention_max_copies is 4, and there are 12 backups present, but all of them are younger than $v_retention_min_days days, none of them are removed
### Backups should not be removed if they have a "_hold" file
### Whether or not backups are being taken was already tested in 006 and 009

function fn_test_12_1 {
	echo "12.1. Is backup pruning working as anticipated when using \"--prune\"?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Test that the correct number of backups are being retained
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234510
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234520
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234530
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234540
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234550
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 3

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 3 ]]; then
		fn_fail "12.1.1"
	fi
	fn_pass "12.1.1"

	### Test the the minimum number of days is being held to
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$( date --date="-1 day" +%s )"0
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$( date --date="-2 days" +%s )"0
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$( date --date="-3 days" +%s )"0
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$( date --date="-4 days" +%s )"0
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$( date --date="-5 days" +%s )"0
	#sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 6

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 6 ]]; then
		fn_fail "12.1.2"
	fi
	fn_pass "12.1.2"

	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 2

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 4 ]]; then
		fn_fail "12.1.3"
	fi
	fn_pass "12.1.3"

	### Test that the minimum number is being retained even if they're too old
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 2

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 4 ]]; then
		fn_fail "12.1.4"
	fi
	fn_pass "12.1.4"

	### Test that files marked as being held are not being removed
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_hold
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 2

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 5 ]]; then
		fn_fail "12.1.5"
	fi
	fn_pass "12.1.5"

	### Test that when a orphaned "_hold" "_ctime" or "_comment" file is present, it is being appropriately removed
	rm -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_comment
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_hold
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_stat
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_md5
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500_pointer
	local v_NOW="$( date +%s )"6
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$v_NOW"_hold
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$v_NOW"_stat
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$v_NOW"_comment
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$v_NOW"_md5
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_"$v_NOW"_pointer
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 2
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_1234500_" ) -ne 0 ]]; then
		fn_fail "12.1.6.1"
	elif [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_${v_NOW}_" ) -ne 0 ]]; then
		fn_fail "12.1.6.2"
	fi
	fn_pass "12.1.6"

	### Verify that pruning is correctly recursing
	mkdir -p "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234500
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234510
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234520
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234530
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234540
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir/123.php_1234550
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 4 --backup-md 2
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/subdir | egrep -c "123.php_[0-9]+$" ) -ne 4 ]]; then
		fn_fail "12.1.7"
	fi
	fn_pass "12.1.7"
}

function fn_test_12_2 {
	echo "12.2. Is backup pruning working as anticipated with \"--diff\"?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Create a backup and verify its presence
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "12.2.1"
	fi
	fn_pass "12.2.1"

	### If no changes have been made to the file, there's no reason to detect that we're out of bounds on the number of backups present
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234500
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234510
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234520
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234530
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234540
	touch "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_1234550
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup-mc 3 --backup-md 3 --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 7 ]]; then
		fn_fail "12.2.2"
	fi
	fn_pass "12.2.2"

	### When a change to the file is detected, that's when backups should be pruned - UNLESS the "--no-check-retention" flag is used
	sleep 1.1
	echo "11111" > "$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --no-check-retention --backup-mc 3 --backup-md 3 --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 8 ]]; then
		fn_fail "12.2.3"
	fi
	fn_pass "12.2.3"

	### Without that flag, however, the older ones should be pruned
	sleep 1.1
	echo "22222" > "$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup-mc 3 --backup-md 3 --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null

	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 3 ]]; then
		fn_fail "12.2.4"
	fi
	fn_pass "12.2.4"

	### No need to re-test other aspects, as it's the saem functions that they're being routed through
}

fn_test_12_1 "$@"
rm -rf "$d_STATWATCH_TESTS_WORKING"
fn_test_12_2 "$@"







