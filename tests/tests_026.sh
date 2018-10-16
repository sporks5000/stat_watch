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

	### Both of these names should be able to be used to reference the backup equally well
	f_BACKUP="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123Ͼ456\.php_[0-9]+$" )"
	f_BACKUP2="$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123Ͼ456\.php_[0-9]+$" )"

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
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$f_BACKUP2"
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
	"$f_STAT_WATCH" --config "$f_CONF" --comment "$f_BACKUP2" "This is a comment"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "26.4.2"
	fi
	### Verify that it's not listed as held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "This is a comment" ) -ne 1 ]]; then
		fn_fail "26.4.3"
	fi
	fn_pass "26.4"

	### Verify that "--hold" can be followed by "--comment"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_DISP="$( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" | egrep "\s--\s" | tail -n1 | cut -d \' -f2 )"
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$v_DISP" --comment "SASQUATCH"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" | egrep "\s--\s" | egrep -c "\s--\sHELD" ) -ne 1 ]]; then
		fn_fail "26.5.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" | egrep -A1 "\s--\s" | egrep -c "SASQUATCH" ) -ne 1 ]]; then
		fn_fail "26.5.2"
	fi
	fn_pass "26.5"

	### Verify that "--comment" can be followed by "--hold"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_DISP="$( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123.php" | egrep "\s--\s" | tail -n1 | cut -d \' -f2 )"
	"$f_STAT_WATCH" --config "$f_CONF" --comment "$v_DISP" "SASQUATCH REVENGE" --hold
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123.php" | egrep "\s--\s" | egrep -c "\s--\sHELD" ) -ne 1 ]]; then
		fn_fail "26.6.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123.php" | egrep -A1 "\s--\s" | egrep -c "SASQUATCH REVENGE" ) -ne 1 ]]; then
		fn_fail "26.6.2"
	fi
	fn_pass "26.6"
}

fn_test_26 "$@"
