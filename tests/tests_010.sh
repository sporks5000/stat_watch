#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_9 {
### Sections from test 9 that were used to prep for test 10
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null

	sleep 1.1
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123?456.php"
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123!456.php"
	echo "1236" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
}

function fn_test_10 {
	echo -e "\n10. If there are backed-up files, does \"--list\" work as anticipated?"
	fn_test_9
	if [[ $( "$f_STAT_WATCH" --list "$d_STATWATCH_TESTS_WORKING/"'testing/123?456.php' | fgrep -c "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"'/testing/123?456.php' ) -ne 2 ]]; then
		fn_fail "10.1"
	fi
	fn_pass "10.1"
	if [[ $( "$f_STAT_WATCH" --list "$d_STATWATCH_TESTS_WORKING/"/testing/subdir/abc.txt | fgrep -c "There are no backups of this file" ) -ne 1 ]]; then
		fn_fail "10.2"
	fi
	fn_pass "10.2"
	"$f_STAT_WATCH" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR ." )
	if [[ $( "$f_STAT_WATCH" --list "$d_STATWATCH_TESTS_WORKING"/testing/subdir/abc.txt | fgrep -c "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"'/testing/subdir/abc.txt' ) -ne 1 ]]; then
		fn_fail "10.3"
	fi
	fn_pass "10.3"
	if [[ $( "$f_STAT_WATCH" --list "$d_STATWATCH_TESTS_WORKING"'/testing/123.php'\'' -- d' | egrep -c "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING""/testing/123.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "10.4"
	fi
	fn_pass "10.4"
}

fn_make_files_1
fn_test_10
