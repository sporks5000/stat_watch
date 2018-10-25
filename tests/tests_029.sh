#! /bin/bash

function fn_test_29 {
	echo "29. Verify that pointer backups are being taken and restored correctly"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### If the backup and the file in place have a different size, do we skip making md5 files
	d_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing"
	chmod 0644 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	echo -n "SASQUATCH" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "123.*md5$" ) -ne 0 ]]; then
		fn_fail "29.1"
	fi
	fn_pass "29.1"

	### If the backup and the file in place have the same size, but different permissions, will an md5sum file be made
	chmod 0600 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "123.*md5$" ) -ne 2 ]]; then
		fn_fail "29.2.1"
	fi
	if [[ $( \ls -1 "$d_BACKUP" | egrep -c "123\.php_[0-9]+$" ) -ne 3 ]]; then
		fn_fail "29.2.2"
	fi
	fn_pass "29.2"

	### If those two backups turn out to have the same content, will a pointer file be correctly made
	v_FILE="$d_BACKUP/""$( \ls -1 "$d_BACKUP" | egrep "_pointer" )"
	v_FILE="$d_BACKUP/123.php_""$( cat "$v_FILE" )"
	if [[ "$( cat "$v_FILE" )" != "SASQUATCH" ]]; then
		fn_fail "29.3"
	fi
	fn_pass "29.3"

	### Change the permissions again
	sleep 1.1
	chmod 0611 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### If we attempt to restore from the first of the two pointer files, is the correct content restored
	v_FILE="$d_STATWATCH_TESTS_WORKING/testing/123.php_""$( \ls -1 "$d_BACKUP" | egrep "_pointer$" | sort | head -n1 | rev | cut -d "_" -f2 | rev )"
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$v_FILE"
	if [[ "$( stat -c %a "$d_STATWATCH_TESTS_WORKING/testing/123.php" )" != "644" ]]; then
		fn_fail "29.4.1"
	fi
	v_FILE="$d_BACKUP/""$( \ls -1 "$d_BACKUP" | egrep "_[0-9]+$" | sort | tail -n1 )"
	if [[ "$( cat "$v_FILE" )" != "SASQUATCH" ]]; then
		fn_fail "29.4.2"
	fi
	fn_pass "29.4"

	### If we attempt to restore from the second pointer file is the correct content restored?
	sleep 1.1
	chmod 0622 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### This time refer to it by the full path rather than the display name
	v_FILE="$d_BACKUP/123.php_""$( \ls -1 "$d_BACKUP" | egrep "_pointer$" | sort | head -n2 | tail -n1 | rev | cut -d "_" -f2 | rev )"
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$v_FILE"
	if [[ "$( stat -c %a "$d_STATWATCH_TESTS_WORKING/testing/123.php" )" != "600" ]]; then
		fn_fail "29.5.1"
	fi
	v_FILE="$d_BACKUP/""$( \ls -1 "$d_BACKUP" | egrep "_[0-9]+$" | sort | tail -n1 )"
	if [[ "$( cat "$v_FILE" )" != "SASQUATCH" ]]; then
		fn_fail "29.5.2"
	fi
	fn_pass "29.5"

	### Test backing up and restoring a symlink	
	ln -sf "$d_STATWATCH_TESTS_WORKING/testing" "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php"
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_BACKUP="$d_BACKUP""/subdir/123 456.php_""$( \ls -1 "$d_BACKUP"/subdir | egrep "123 456.php_[0-9]+$" | egrep -o "[0-9]+$" | head -n1 )"
	rm -f "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php"
	ln -sf "$d_STATWATCH_TESTS_WORKING/testing" "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ ! -d "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" ]]; then
		fn_fail "29.6.1"
	fi
		"$f_STAT_WATCH" --config "$f_CONF" --restore "$v_BACKUP"
	if [[ ! -d "$d_STATWATCH_TESTS_WORKING/testing/subdir/123 456.php" ]]; then
		fn_fail "29.6.2"
	fi
	fn_pass "29.6"
}

fn_test_29 "$@"
