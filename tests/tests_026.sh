#! /bin/bash

function fn_test_26 {
	echo "26. Verify functionality of \"--hold\", \"--unhold\", and \"--comment\""
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Backup a file
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	f_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123Ͼ456\.php_[0-9]+$" )"
	### Verify that the backup exists
	if [[ ! -n "$f_BACKUP" || ! -f "$f_BACKUP" ]]; then
		fn_fail "26.1.1"
	fi
	### Verify that it's listed
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "26.1.2"
	fi
	### Verify that it's not listed as held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep "\s--\s" | egrep -c "\s--\sHELD" ) -ne 0 ]]; then
		fn_fail "26.1.3"
	fi
	fn_pass "26.1"

	### Hold the backup
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$f_BACKUP"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "26.2.2"
	fi
	### Verify that it's not listed as held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep "\s--\s" | egrep -c "\s--\sHELD" ) -ne 1 ]]; then
		fn_fail "26.2.3"
	fi
	fn_pass "26.2"

	### Unhold the backup
	"$f_STAT_WATCH" --config "$f_CONF" --unhold "$f_BACKUP"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "26.3.2"
	fi
	### Verify that it's not listed as held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep "\s--\s" | egrep -c "\s--\sHELD" ) -ne 0 ]]; then
		fn_fail "26.3.3"
	fi
	fn_pass "26.3"

	### Add a comment for the backup
	"$f_STAT_WATCH" --config "$f_CONF" --comment "$f_BACKUP" "This is a comment"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "26.4.2"
	fi
	### Verify that it's not listed as held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "This is a comment" ) -ne 1 ]]; then
		fn_fail "26.4.3"
	fi
	fn_pass "26.4"
}

fn_test_26 "$@"
