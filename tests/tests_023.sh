#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_23 {
	echo -e "\n23. test assumptions to ensure that they are working as expected"

	### Given a job file and a directory, is the assumption created as expected
	f_JOB="$d_STATWATCH_TESTS_WORKING"/testing2/test.job
	echo -e "BackupD $d_STATWATCH_TESTS_WORKING/testing2/backup\nBackup+ $d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" > "$f_JOB"
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB" "$d_STATWATCH_TESTS_WORKING"/testing/ > /dev/null
	if [[ ! -f "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions ]]; then
		fn_fail "23.1"
	fi
	fn_pass "23.1"

	### Go to the directory and test if backing up a file works
	cd "$d_STATWATCH_TESTS_WORKING"/testing/
	"$f_STAT_WATCH" --config "$f_CONF" -a 123.php >/dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 1 ]]; then
		fn_fail "23.2"
	fi
	fn_pass "23.2"

	### Create an assumption for the current directory using only the job file
	rm -f "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB" > /dev/null
	if [[ ! -f "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions ]]; then
		fn_fail "23.3"
	fi
	fn_pass "23.3"

	### Verify that the assumption DOES NOT work outside of the directory
	cd "$d_STATWATCH_TESTS"
	sleep 1.1
	echo "123456" > "$d_STATWATCH_TESTS_WORKING"/testing/123.php
	"$f_STAT_WATCH" --config "$f_CONF" -a "$d_STATWATCH_TESTS_WORKING"/testing/123.php >/dev/null 2>&1 || true
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 1 ]]; then
		fn_fail "23.4"
	fi
	fn_pass "23.4"

	### And just to be sure, run the same command with the include and see that it worked
	sleep 1.1
	echo "123458" > "$d_STATWATCH_TESTS_WORKING"/testing/123.php
	"$f_STAT_WATCH" --config "$f_CONF" -a "$d_STATWATCH_TESTS_WORKING"/testing/123.php -i "$f_JOB" >/dev/null
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/123.php_* | egrep -cv "ctime$" ) -ne 2 ]]; then
		fn_fail "23.5"
	fi
	fn_pass "23.5"	
}

fn_make_files_1
fn_test_23
