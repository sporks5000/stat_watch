#! /bin/bash

function fn_test_27 {
	echo "27. Verify functionality of \"--restore\""
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	d_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing
	### Make backups of filenames with special characters
	"$f_STAT_WATCH" --config "$f_CONF" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup -a "$d_STATWATCH_TESTS_WORKING"/testing/123.php"' -- d" "$d_STATWATCH_TESTS_WORKING/testing/123'456.php" "$d_STATWATCH_TESTS_WORKING/testing/123\"456.php" "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" "$d_STATWATCH_TESTS_WORKING"'/testing/123!456.php' "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/123\n456.php" )" "$d_STATWATCH_TESTS_WORKING/testing/123ᡘ456.php" "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/subdir/123\0010456.html" )" "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/subdir/123\0033456.html" )" "$d_STATWATCH_TESTS_WORKING/testing/subdir/123💩456.php"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING"/testing/123.php"' -- d" "$d_STATWATCH_TESTS_WORKING/testing/123'456.php" "$d_STATWATCH_TESTS_WORKING/testing/123\"456.php" "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" "$d_STATWATCH_TESTS_WORKING"'/testing/123!456.php' "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/123\n456.php" )" "$d_STATWATCH_TESTS_WORKING/testing/123ᡘ456.php" "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/subdir/123\0010456.html" )" "$( echo -e "$d_STATWATCH_TESTS_WORKING/testing/subdir/123\0033456.html" )" "$d_STATWATCH_TESTS_WORKING/testing/subdir/123💩456.php" | egrep -c "\s--\s" ) -ne 11 ]]; then
		fn_fail "27.1"
	fi
	fn_pass "27.1"

	### Create a file with all of the special characters
	fn_make_files_2
	local v_FILE="$d_STATWATCH_TESTS_WORKING"/testing/"$v_ANGRY".png
	echo "1234" > "$v_FILE"
	"$f_STAT_WATCH" --config "$f_CONF" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup -a "$v_FILE"
	### Make sure that it lists
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$v_FILE" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "27.2.1"
	fi
	### Make sure that we've actually captured the name of the backup
	local v_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$v_FILE"_"$( \ls -1 "$d_BACKUP" | egrep "png" | egrep -v "stat" | egrep -o "[0-9]+$" )"
	if [[ ! -f "$v_BACKUP" ]]; then
		fn_fail "27.2.2"
	fi
	fn_pass "27.2"

	### Modify the file, then restore the earlier version
	sleep 1.1
	echo "56789" > "$v_FILE"
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$v_BACKUP" > /dev/null
	if [[ "$( cat "$v_FILE" )" != "1234" ]]; then
		fn_fail "27.3.1"
	fi
	### Make sure that both the previous version and the restored version were backed up
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$v_FILE" | egrep -c "\s--\s" ) -ne 3 ]]; then
		fn_fail "27.3.2"
	fi
	### Make sure that a comment was added to the most recent version of the file
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$v_FILE" | egrep -c "Restored from backup taken at" ) -ne 1 ]]; then
		fn_fail "27.3.3"
	fi
	fn_pass "27.3"

	### Test backing up and restoring a symlink	
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_BACKUP="$d_BACKUP""/subdir/123 456.php_""$( \ls -1 "$d_BACKUP"/subdir | egrep "123 456.php_[0-9]+$" | egrep -o "[0-9]+$" | head -n1 )"
	ln -sf "$d_STATWATCH_TESTS_WORKING/testing" "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ ! -d "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" ]]; then
		fn_fail "27.4.1"
	fi
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$v_BACKUP" > /dev/null
	if [[ -d "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" ]]; then
		fn_fail "27.4.2"
	fi
	fn_pass "27.4"
}

fn_test_27 "$@"
