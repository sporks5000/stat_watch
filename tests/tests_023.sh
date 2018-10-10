#! /bin/bash

function fn_test_23 {
	echo "23. Test assumptions to ensure that they are working as expected"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

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

	### Test to ensure that creating a new assumption one directory up from an existing assumption does not remove the existing assumption
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions | wc -l ) -ne 1 ]]; then
		fn_fail "23.6.1"
	fi
	cp -a "$f_JOB" "$f_JOB"2
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB"2 "$d_STATWATCH_TESTS_WORKING" > /dev/null
	### Verify a new line has been added
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions | wc -l ) -ne 2 ]]; then
		fn_fail "23.6.2"
	fi
	### Verify that we're given the right directory as output
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --assume "$d_STATWATCH_TESTS_WORKING" | egrep -c "$( fn_sanitize "$f_JOB"2 )" ) -ne 1 ]]; then
		fn_fail "23.6.3"
	fi
	fn_pass "23.6"

	### Test "--remove" functionality
	"$f_STAT_WATCH" --config "$f_CONF" --assume --remove "$d_STATWATCH_TESTS_WORKING" > /dev/null
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions | wc -l ) -ne 1 ]]; then
		fn_fail "23.7.1"
	fi	
	### Verify that we're told no directories match
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --assume "$d_STATWATCH_TESTS_WORKING" | egrep -c "No assumed job for directory" ) -ne 1 ]]; then
		fn_fail "23.7.2"
	fi
	### Verify that assumptions in deeper directories remain intact
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --assume "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "$( fn_sanitize "$f_JOB" )" ) -ne 1 ]]; then
		fn_fail "23.7.3"
	fi
	fn_pass "23.7"
	
	### Test to ensure that creating a new assumption for a directory with an existing assumption successfully overwrites the existing assumption
	"$f_STAT_WATCH" --config "$f_CONF" --assume "$f_JOB"2 "$d_STATWATCH_TESTS_WORKING"/testing > /dev/null
	if [[ $( cat "$d_STATWATCH_TESTS_WORKING"/testing2/working/assumptions | wc -l ) -ne 1 ]]; then
		fn_fail "23.8.1"
	fi
	### Verify that we're given the right directory as output
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --assume "$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "$( fn_sanitize "$f_JOB"2 )" ) -ne 1 ]]; then
		fn_fail "23.8.2"
	fi
	fn_pass "23.8"
}

fn_test_23 "$@"
