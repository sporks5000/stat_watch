#! /bin/bash

function fn_test_22 {
	echo "22. Test to ensure that --backup-file is working as anticipated (including \"--hold\" and \"--comment\" functionality)"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Make sure that a file that was not explicitly requested to be backed up was backed up
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	"$f_STAT_WATCH" --config "$f_CONF" --backup "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --backup+ "$d_STATWATCH_TESTS_WORKING/testing/123Ͼ456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "22.1"
	fi
	fn_pass "22.1"

	### Now backup that file. Make sure that it and the ctime file exists
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "22.2.1"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_ctime$" ) -ne 1 ]]; then
		fn_fail "22.2.2"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_comment$" ) -ne 0 ]]; then
		fn_fail "22.2.3"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_hold$" ) -ne 0 ]]; then
		fn_fail "22.2.4"
	fi
	fn_pass "22.2"

	### "-a" should be an alias for "--backup-file"
	"$f_STAT_WATCH" --config "$f_CONF" -a "$d_STATWATCH_TESTS_WORKING"'/testing/123!456.php' --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c '123!456\.php_[0-9]+$' ) -ne 1 ]]; then
		fn_fail "22.3"
	fi
	fn_pass "22.3"

	### Attempting to create a second backup without the file being changed, should result in no second backup being created
	f_BACKUP1="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123\?456\.php_[0-9]+$" )"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "22.4"
	fi
	fn_pass "22.4"

	### If we change the file, however, a seonc file should be created
	sleep 1.1
	echo "11111" > "$d_STATWATCH_TESTS_WORKING/testing/123?456.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "22.5"
	fi
	fn_pass "22.5"

	### If we ask for a file to be held, and the most recent backup matches, the hold should be applied to that backup
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --hold
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "22.6.1"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_hold$" ) -ne 1 ]]; then
		fn_fail "22.6.2"
	fi
	f_BACKUP2="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123\?456\.php_[0-9]+_hold$" | sed "s/_hold$//" )"
	if [[ "$f_BACKUP1" == "$f_BACKUP2" ]]; then
		fn_fail "22.6.3"
	fi
	if [[ ! -f "$f_BACKUP2"_hold ]]; then
		fn_fail "22.6.4"
	fi
	if [[ -f "$f_BACKUP1"_hold ]]; then
		fn_fail "22.6.5"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_comment$" ) -ne 0 ]]; then
		fn_fail "22.6.6"
	fi
	fn_pass "22.6"

	### If we comment on a file and the most recent backup matches, the hold should be applied to that backup
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --comment 'very nice!'
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "22.7.1"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_comment$" ) -ne 1 ]]; then
		fn_fail "22.7.2"
	fi
	f_BACKUP3="$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing/"$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep "123\?456\.php_[0-9]+_comment$" | sed "s/_comment$//" )"
	if [[ "$f_BACKUP1" == "$f_BACKUP3" || "$f_BACKUP2" != "$f_BACKUP3" ]]; then
		fn_fail "22.7.3"
	fi
	if [[ ! -f "$f_BACKUP3"_comment ]]; then
		fn_fail "22.7.4"
	fi
	if [[ -f "$f_BACKUP1"_comment ]]; then
		fn_fail "22.7.5"
	fi
	if [[ $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING"/testing | egrep -c "123\?456\.php_[0-9]+_comment$" ) -ne 1 ]]; then
		fn_fail "22.7.6"
	fi
	fn_pass "22.7"

	### "--list" should show that the file is held
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" | egrep -c "$( fn_sanitize "$f_BACKUP3" ).* -- HELD" ) -ne 1 ]]; then
		fn_fail "22.8"
	fi
	fn_pass "22.8"

	### "--list" should also show the comment
	if [[ $( "$f_STAT_WATCH" --config "$f_CONF" --list "$d_STATWATCH_TESTS_WORKING/testing/123?456.php" | egrep -A1 "$( fn_sanitize "$f_BACKUP3" ).* -- HELD" | egrep -c "very nice" ) -ne 1 ]]; then
		fn_fail "22.9"
	fi
	fn_pass "22.9"
}

fn_test_22 "$@"
