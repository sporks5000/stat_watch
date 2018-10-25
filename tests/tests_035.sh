#! /bin/bash

function fn_test_35 {
	echo "35. Given a '__prune_rules' file, are those rules being followed as anticipated?"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sleep 1.1
	cp -a "$d_STATWATCH_TESTS_WORKING"/testing/subdir "$d_STATWATCH_TESTS_WORKING"/testing/subdir2
	fn_change_files_1
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	"$f_STAT_WATCH" --config "$f_CONF" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt --backup -i <( echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null

	### check to make sure that all of the files are there
	d_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup/"$d_STATWATCH_TESTS_WORKING"/testing
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "^123Ͼ456.php_[0-9]+$" ) -ne 1 || $( \ls -1 "$d_BACKUP/subdir" | egrep -c "^456.php_[0-9]+$" ) -ne 1 || $( \ls -1 "$d_BACKUP/subdir2" | egrep -c "^123.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "35.1"
	fi
	fn_pass "35.1"

	### Create me up some files
	for i in 1 2 3 4 5 6 7 8; do
		v_DATE="$( date --date="now - $i days" +%s )"
		echo -n "11235" > "$d_BACKUP"/123Ͼ456.php_"$v_DATE""$i"
		echo -n "11235" > "$d_BACKUP"/subdir/456.php_"$v_DATE""$i"
		echo -n "11235" > "$d_BACKUP"/subdir2/123.php_"$v_DATE""$i"
	done

	### Make sure that they're present
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "^123Ͼ456.php_[0-9]+$" ) -ne 9 || $( \ls -1 "$d_BACKUP/subdir" | egrep -c "^456.php_[0-9]+$" ) -ne 9 || $( \ls -1 "$d_BACKUP/subdir2" | egrep -c "^123.php_[0-9]+$" ) -ne 9 ]]; then
		fn_fail "35.2"
	fi
	fn_pass "35.2"

	### Make a backup of this directory, because I'll want it just as it is a few more times
	cp -a "$d_BACKUP" "$d_BACKUP"_

	### If the main directory has a prune rules file, are those rules being followed instead of rules given at the command line
	sleep 1.1
	echo -n "4:4" > "$d_BACKUP"/__prune_rules
	"$f_STAT_WATCH" --config "$f_CONF" --prune -i <( echo -e "BackupMC 6\nBackupMD 6\nBackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "^123Ͼ456.php_[0-9]+$" ) -ne 4 || $( \ls -1 "$d_BACKUP/subdir" | egrep -c "^456.php_[0-9]+$" ) -ne 4 || $( \ls -1 "$d_BACKUP/subdir2" | egrep -c "^123.php_[0-9]+$" ) -ne 4 ]]; then
		fn_fail "35.3"
	fi
	fn_pass "35.3"

	### If the main directory does not have a prune rules file, and the first of two subdirectories does but the other doesn't, will the rules from the first subdirectory ONLY be applied to files within that subdirectory
	rm -rf "$d_BACKUP"
	cp -a "$d_BACKUP"_ "$d_BACKUP"
	echo -n "4:4" > "$d_BACKUP"/subdir/__prune_rules
	"$f_STAT_WATCH" --config "$f_CONF" --prune -i <( echo -e "BackupMC 6\nBackupMD 6\nBackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "^123Ͼ456.php_[0-9]+$" ) -ne 6 || $( \ls -1 "$d_BACKUP/subdir" | egrep -c "^456.php_[0-9]+$" ) -ne 4 || $( \ls -1 "$d_BACKUP/subdir2" | egrep -c "^123.php_[0-9]+$" ) -ne 6 ]]; then
		fn_fail "35.4"
	fi
	fn_pass "35.4"

	### If the main subdirectory has rules, the first subdirectory has different rules, and the second subdirectory has no rules, will the rules from the main directory be correctly applied to the second directory
	rm -rf "$d_BACKUP"
	cp -a "$d_BACKUP"_ "$d_BACKUP"
	echo -n "4:4" > "$d_BACKUP"/__prune_rules
	echo -n "5:5" > "$d_BACKUP"/subdir/__prune_rules
	"$f_STAT_WATCH" --config "$f_CONF" --prune -i <( echo -e "BackupMC 6\nBackupMD 6\nBackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "^123Ͼ456.php_[0-9]+$" ) -ne 4 || $( \ls -1 "$d_BACKUP/subdir" | egrep -c "^456.php_[0-9]+$" ) -ne 5 || $( \ls -1 "$d_BACKUP/subdir2" | egrep -c "^123.php_[0-9]+$" ) -ne 4 ]]; then
		fn_fail "35.5"
	fi
	fn_pass "35.5"
}

fn_test_35 "$@"
