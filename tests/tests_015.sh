#! /bin/bash

function fn_test_15 {
	echo "15. Verify that the \"BACKUP_DIRECTORY\" configuration directive is functioning as expected"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Make sure that we get the appropriate error when trying to backup without a directory
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" > /dev/null 2>&1
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123.php" | egrep -c "There are no backups of this file" ) -ne 1 ]]; then
		fn_fail "15.1"
	fi
	fn_pass "15.1"

	### Add the directive and try again
	echo "BACKUP_DIRECTORY = $d_STATWATCH_TESTS_WORKING/testing2/backup" >> "$f_CONF"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123.php" | egrep -c "There are no backups of this file" ) -ne 0 ]]; then
		fn_fail "15.2"
	fi
	fn_pass "15.2"
}

fn_test_15 "$@"
