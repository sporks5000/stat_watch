#! /bin/bash

function fn_test_6 {
	echo "6.  Does the \"--backup\" flag work as expected"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Create a situation where one file should be backed up - is it?
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "6.1.1"
	fi
	### Make sure that the stat file is there as well
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+_stat$" ) -ne 1 ]]; then
		fn_fail "6.1.2"
	fi
	fn_pass "6.1"

	### Verify that the information stored in the stat file is correct
	local v_CTIME1="$( stat -c %Z "$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php )"
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456.php_*_stat | egrep -c " -- $v_CTIME1 -- [^ ]+$" ) -ne 1 ]]; then
		fn_fail "6.2"
	fi
	fn_pass "6.2"
	
	### Test to see if a second backup will be made in spite of there having been no changes to the file
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "6.3"
	fi
	fn_pass "6.3"

	### Change the file; make sure that a second backup is made
	sleep 1.1
	fn_change_files_1
	echo -n "12" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "6.4"
	fi
	fn_pass "6.4"

	### Test regular expression matching
	fn_remove_files
	fn_make_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backupr '\.php$' --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 8 ]]; then
		fn_fail "6.5.1"
	fi
	### Make sure that files that should not have matched the regex were NOT nacked up.
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 && $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/subdir | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "6.5.2"
	fi
	fn_pass "6.5"

	### Make changes to some of the files; verify that they are backed up again
	sleep 1.1
	echo "12356" > "$d_STATWATCH_TESTS_WORKING/testing/123?456.php"
	echo "12356" > "$d_STATWATCH_TESTS_WORKING/testing/123!456.php"
	echo "12356" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backupr '\.php$' --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 11 ]]; then
		fn_fail "6.6"
	fi
	fn_pass "6.6"
}

fn_test_6 "$@"
