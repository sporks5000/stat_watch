#! /bin/bash

function fn_test_28 {
	echo "28. Given a path that includes a symlink, is Stat Watch working as expected"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Backup using the path, then list using the link
	ln -s "$d_STATWATCH_TESTS_WORKING" "$d_STATWATCH_TESTS"/symlink
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS/symlink/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "28.1.1"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS/symlink/testing/123Ͼ456.php" | egrep -c "symlink" ) -ne 0 ]]; then
		echo "This may be a false failure if your installation path includes the string \"symlink\""
		fn_fail "28.1.2"
	fi
	fn_pass "28.1"

	### backup using the link, then list using the path
	rm -rf "$d_STATWATCH_TESTS_WORKING"/testing2/backup/*
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 0 ]]; then
		fn_fail "28.2.1"
	fi
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS/symlink/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 1 ]]; then
		fn_fail "28.2.2"
	fi
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS/symlink/testing/123Ͼ456.php" | egrep -c "symlink" ) -ne 0 ]]; then
		echo "This may be a false failure if your installation path includes the string \"symlink\""
		fn_fail "28.2.3"
	fi
	fn_pass "28.2"

	### Apply a hold to a backed up file, referencing it by the symlink
	f_BACKUP="$d_STATWATCH_TESTS"/symlink/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123Ͼ456\.php_[0-9]+$" )"
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$f_BACKUP"
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\sHELD" ) -ne 1 ]]; then
		fn_fail "28.3"
	fi
	fn_pass "28.3"

	### Restore a file referenced by the symlink
	sleep 1.1
	echo "123567" > "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$f_BACKUP" > /dev/null
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" | egrep -c "\s--\s" ) -ne 3 ]]; then
		fn_fail "28.4.1"
	fi
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" ) != "1234" ]]; then
		fn_fail "28.4.2"
	fi
	fn_pass "28.4"

	### With "--record" does it show the correct path?
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "symlink" ) -ne 0 ]]; then
		echo "This may be a false failure if your installation path includes the string \"symlink\""
		fn_fail "28.5"
	fi
	fn_pass "28.5"

	### Create an assumption referencing the symlink
	rm -rf "$d_STATWATCH_TESTS_WORKING"/testing2/backup/*
	f_JOB="$d_STATWATCH_TESTS_WORKING"/testing2/test.job
	echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" > "$f_JOB"
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB" "$d_STATWATCH_TESTS"/symlink/testing/ > /dev/null

	### Go to the directory by the correct name and test if backing up a file works
	cd "$d_STATWATCH_TESTS_WORKING"/testing/
	"$f_STAT_WATCH" --config "$f_CONF" -a 123.php >/dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 1 ]]; then
		fn_fail "28.6"
	fi
	fn_pass "28.6"

	### Go to the directory referenced by the symlink and test if backing up a file works
	rm -rf "$d_STATWATCH_TESTS_WORKING"/testing2/backup/*
	cd "$d_STATWATCH_TESTS"/symlink/testing/
	"$f_STAT_WATCH" --config "$f_CONF" -a 123.php >/dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 1 ]]; then
		fn_fail "28.7"
	fi
	fn_pass "28.7"

	### Create an assumption for the PWD when the PWD is referenced by the symlink, then go to the directory referenced correctly. Will the assumption work
	rm -rf "$d_STATWATCH_TESTS_WORKING"/testing2/backup/*
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB" > /dev/null
	cd "$d_STATWATCH_TESTS_WORKING"/testing/
	"$f_STAT_WATCH" --config "$f_CONF" -a 123.php >/dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 1 ]]; then
		fn_fail "28.8"
	fi
	fn_pass "28.8"
}

fn_test_28 "$@"
rm -f "$d_STATWATCH_TESTS"/symlink
