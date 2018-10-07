#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_9 {
	echo -e "\n9.  Do the backups work as expected with \"--diff\""

	### Create a situation where one file should be backed up. Is it?
	"$f_STAT_WATCH" --config "" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --config "" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "9.1.1"
	fi
	### Make sure that the ctime file is there as well
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456\.php_[0-9]+_ctime$" ) -ne 1 ]]; then
		fn_fail "9.1.2"
	fi
	fn_pass "9.1"

	### Using the same diffs, it should once again think that the file changed. But the file comparison process should prevent a second backup from being made
	"$f_STAT_WATCH" --config "" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "9.2"
	fi
	fn_pass "9.2"

	### If we change the ctime, however, it should result in a second backup being made
	sleep 1.1
	local f_CTIME="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123Ͼ456\.php_*_ctime )"
	date +%s > "$f_CTIME"
	"$f_STAT_WATCH" --config "" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "9.3"
	fi
	fn_pass "9.3"

	### Test regular expressions
	fn_remove_files
	fn_make_files_1
	"$f_STAT_WATCH" --config "" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --config "" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 7 ]]; then
		fn_fail "9.4.1"
	fi
	### Make sure that the files that should not have been matched were not backed up
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 && $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/subdir | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "9.4.2"
	fi
	fn_pass "9.4"

	### Given changes to some of those files, make sure that they are backed up again
	sleep 1.1
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123?456.php"
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123!456.php"
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "\.php_[0-9]+$" ) -ne 10 ]]; then
		fn_fail "9.5"
	fi
	fn_pass "9.5"
}

fn_make_files_1
fn_test_9
