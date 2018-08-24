#! /bin/bash

### This file contains tests for stat_watch.pl to ensure that it is functioning as anticipated
### All future versions of stat_watch.pl will be run against this script in order to ensure that no changes have broken desired functionality

v_PROGRAMDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -z "$v_PROGRAMDIR" || ! -d "$v_PROGRAMDIR" ]]; then
	echo "Attempt to capture the program directory failed"
	exit 1;
else
	v_PROGRAMDIR="$( cd "$v_PROGRAMDIR" && cd ../ && pwd -P )"
fi
f_STAT_WATCH="$v_PROGRAMDIR"/stat_watch.pl
if [[ ! -f "$f_STAT_WATCH" || ! -e "$f_STAT_WATCH" ]]; then
	echo "stat_watch.pl must be present and executable one directory level up from the directory where this script exists"
	exit 1;
fi

function fn_make_files_1 {
	mkdir -p "$v_PROGRAMDIR"/testing
	mkdir -p "$v_PROGRAMDIR"/testing2
	mkdir -p "$v_PROGRAMDIR"/testing2/backup
	mkdir -p "$v_PROGRAMDIR"/testing/subdir
	echo "1234" > "$v_PROGRAMDIR"/testing/123.php
	echo "1234" > "$v_PROGRAMDIR"/testing/123.php"' -- d"
	echo "1234" > "$v_PROGRAMDIR"/testing/subdir/123.php
	echo "1234" > "$v_PROGRAMDIR/testing/123'456.php"
	echo "1234" > "$v_PROGRAMDIR/testing/123\"456.php"
	echo "1234" > "$v_PROGRAMDIR/testing/123?456.php"
	echo "1234" > "$v_PROGRAMDIR"'/testing/123!456.php'
	echo "1234" > "$( echo -e "$v_PROGRAMDIR/testing/123\n456.php" )"
	echo "1234" > "$v_PROGRAMDIR/testing/123ᡘ456.php"
	echo "1234" > "$v_PROGRAMDIR/testing/123Ͼ456.php"
	echo "1234" > "$v_PROGRAMDIR/testing/abc.txt"
	echo "1234" > "$v_PROGRAMDIR"/testing/subdir/abc.txt
	echo "1234" > "$( echo -e "$v_PROGRAMDIR/testing/subdir/123\0010456.html" )"
	echo "1234" > "$( echo -e "$v_PROGRAMDIR/testing/subdir/123\0033456.html" )"
	rm -f "$v_PROGRAMDIR"/testing/subdir/456.php
}

function fn_change_files_1 {
	rm -f "$v_PROGRAMDIR"/testing/123.php
	echo "1235" > "$v_PROGRAMDIR"/testing/123.php"' -- d"
	echo "1235" > "$v_PROGRAMDIR"/testing/subdir/123.php
	echo "1235" > "$v_PROGRAMDIR/testing/123'456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/123\"456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/123?456.php"
	echo "1235" > "$v_PROGRAMDIR"'/testing/123!456.php'
	echo "1235" > "$( echo -e "$v_PROGRAMDIR/testing/123\n456.php" )"
	echo "1235" > "$v_PROGRAMDIR/testing/123ᡘ456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/123Ͼ456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/abc.txt"
	echo "1235" > "$v_PROGRAMDIR"/testing/subdir/abc.txt
	echo "1235" > "$( echo -e "$v_PROGRAMDIR/testing/subdir/123\0010456.html" )"
	echo "1235" > "$( echo -e "$v_PROGRAMDIR/testing/subdir/123\0033456.html" )"
	echo "1235" > "$v_PROGRAMDIR"/testing/subdir/456.php
}

function fn_remove_files {
	rm -rf "$v_PROGRAMDIR"/testing
	rm -rf "$v_PROGRAMDIR"/testing2
	rm -f "$v_PROGRAMDIR"/.stat_watch/backup_locations
}

function fn_fail {
	echo -e "\e[91m""Test $1 FAILED""\e[0m"
	echo
	echo "To assist with troubleshooting, it might be helpful to run the following command:"
	echo "     v_PROGRAMDIR=\"\$( pwd -P )\"; f_STAT_WATCH=\"\$v_PROGRAMDIR\"/stat_watch.pl"
	echo
	echo "To clean the working files, run:"
	echo "     $v_PROGRAMDIR/.stat_watch/tests.sh --clean"
	echo
	exit 1;
}

function fn_pass {
	echo -e "\e[32m""Test $1 SUCCESS""\e[0m"
}

function fn_md5_modules {
	v_MODULES=''
	if [[ $( /usr/bin/perl -e "use Digest::MD5;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5"
	fi
	if [[ $( /usr/bin/perl -e "use Digest::MD5::File;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5::File"
	fi
	if [[ -n $v_MODULES ]]; then
		echo
		echo "Attempting to install the necessary perl modules"
		echo
		sleep 2
		/usr/bin/cpan -i $v_MODULES
		if [[ $? -ne 0 ]]; then
			echo "Failed to install perl modules" > /dev/stderr
			exit 1;
		fi
		echo
	fi
	if [[ ! -f "$v_PROGRAMDIR"/.stat_watch/md5.pm ]]; then
		echo "File \"$v_PROGRAMDIR/.stat_watch/md5.pm\" is missing"
		exit 1;
	fi
}

if [[ "$1" == "--clean" ]]; then
	fn_remove_files
	exit
fi

#=================#
#== Begin Tests ==#
#=================#

function fn_test_1 {
	echo -e "\n1.  Given a directory with an additional directory inside, will stat_watch.pl capture details for files within both of these directories"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "testing/(subdir/)?123\.php' -- " ) -ne 3 ]]; then
		fn_fail "1.1"
	fi
	fn_pass "1.1"
}

function fn_test_2 {
	echo -e "\n2.  Will stat_watch.pl recognize file names with special characters, quotes, or new lines"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "testing/123('|\"|\?|!)456\.php' -- " ) -ne 4 ]]; then
		fn_fail "2.1"
	fi
	fn_pass "2.1"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "testing/123_mlfn_[0-9]+456\.php' -- " ) -ne 1 ]]; then
		fn_fail "2.2"
	fi
	fn_pass "2.2"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "testing/123(ᡘ|Ͼ)456\.php' -- " ) -ne 2 ]]; then
		fn_fail "2.3"
	fi
	fn_pass "2.3"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "123""$( echo -e "\0010" )""456\.html" ) -ne 1 ]]; then
		fn_fail "2.4"
	fi
	fn_pass "2.4"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing | egrep -c "12456\.html" ) -ne 0 ]]; then
		fn_fail "2.5"
	fi
	fn_pass "2.5"
}

function fn_test_3 {
	echo -e "\n3.  Will stat_watch.pl recognize changes to files in \"--diff\" mode"
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | egrep -A10 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "testing/(subdir/)?123" ) -ne 9 ]]; then
		fn_fail "3.1"
	fi
	fn_pass "3.1"
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "3.2"
	fi
	fn_pass "3.2"
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "3.3"
	fi
	fn_pass "3.3"
}

function fn_test_4 {
	echo -e "\n4.  If the report files are given in the wrong order, will stat_watch.pl sort them out? Will it avoid sorting them if they have the \"--before\" and \"--after\" flags"
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report2.txt "$v_PROGRAMDIR"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.1"
	fi
	fn_pass "4.1"
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report2.txt "$v_PROGRAMDIR"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.2"
	fi
	fn_pass "4.2"
	if [[ $( "$f_STAT_WATCH" --diff --before "$v_PROGRAMDIR"/testing2/report2.txt --after "$v_PROGRAMDIR"/testing2/report1.txt | egrep -A1 "FILES THAT WERE REMOVED" | egrep -c "testing/subdir/456\.php" ) -ne 1 ]]; then
		fn_fail "4.3"
	fi
	fn_pass "4.3"
	if [[ $( "$f_STAT_WATCH" --diff --before "$v_PROGRAMDIR"/testing2/report2.txt --after "$v_PROGRAMDIR"/testing2/report1.txt | egrep -A1 "FILES THAT WERE NOT PRESENT PREVIOUSLY" | egrep -c "testing/123\.php" ) -ne 1 ]]; then
		fn_fail "4.4"
	fi
	fn_pass "4.4"
}

function fn_test_5 {
	echo -e "\n5.  Will stat_watch.pl raccurately replace paths using the \"--as-dir\" flag?"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --as-dir /home | egrep -c "Processing: '/home'" ) -ne 1 ]]; then
		fn_fail "5.1"
	fi
	fn_pass "5.1"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --as-dir /home | egrep -c "^'/home' -- " ) -ne 1 ]]; then
		fn_fail "5.2"
	fi
	fn_pass "5.2"
	if [[ $( "$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --as-dir /home | egrep -c "^'/home" ) -ne 16 ]]; then
		fn_fail "5.3"
	fi
	fn_pass "5.3"
}

function fn_test_6 {
	echo -e "\n6.  Does the \"--backup\" flag work as expected"
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report1.txt --backup+ "$v_PROGRAMDIR/testing/123Ͼ456.php" --backupd "$v_PROGRAMDIR"/testing2/backup
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "6.1"
	fi
	fn_pass "6.1"
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report1.txt --backup+ "$v_PROGRAMDIR/testing/123Ͼ456.php" --backupd "$v_PROGRAMDIR"/testing2/backup
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 1 ]]; then
		### There were no changes to this file, so a second backup should not have been made
		fn_fail "6.2"
	fi
	fn_pass "6.2"
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report1.txt --backup+ "$v_PROGRAMDIR/testing/123Ͼ456.php" --backupd "$v_PROGRAMDIR"/testing2/backup
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "6.3"
	fi
	fn_pass "6.3"
	fn_remove_files
	fn_make_files_1
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report1.txt --backupr '\.php$' --backupd "$v_PROGRAMDIR"/testing2/backup
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "\.php_[0-9]+$" ) -ne 8 ]]; then
		fn_fail "6.4"
	fi
	fn_pass "6.4"
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 && $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/subdir | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "6.5"
	fi
	fn_pass "6.5"
	sleep 1.1
	echo "1235" > "$v_PROGRAMDIR/testing/123?456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/123!456.php"
	echo "1235" > "$v_PROGRAMDIR/testing/123Ͼ456.php"
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report1.txt --backupr '\.php$' --backupd "$v_PROGRAMDIR"/testing2/backup
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "\.php_[0-9]+$" ) -ne 11 ]]; then
		fn_fail "6.6"
	fi
	fn_pass "6.6"
}

function fn_test_7 {
	echo -e "\n7.  Does gathering md5 sums work?"
	fn_md5_modules
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt --md5
	if [[ $( cat "$v_PROGRAMDIR"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 13 ]]; then
		fn_fail "7.1"
	fi
	fn_pass "7.1"
	"$f_STAT_WATCH" "$v_PROGRAMDIR"/testing -i <( echo "MD5 $v_PROGRAMDIR/testing/123'456.php" ) --output "$v_PROGRAMDIR"/testing2/report1.txt
	if [[ $( cat "$v_PROGRAMDIR"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.2"
	fi
	fn_pass "7.2"
	if [[ $( egrep "testing/123'456\.php" "$v_PROGRAMDIR"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 1 ]]; then
		fn_fail "7.3"
	fi
	fn_pass "7.3"
	"$f_STAT_WATCH" "$v_PROGRAMDIR"/testing -i <( echo "MD5R \.txt$" ) --output "$v_PROGRAMDIR"/testing2/report1.txt
	if [[ $( cat "$v_PROGRAMDIR"/testing2/report1.txt | awk -F" -- " '{print $8}' | egrep -c "^[0-9a-f]{32}$" ) -ne 2 ]]; then
		fn_fail "7.4"
	fi
	fn_pass "7.4"
}

function fn_test_8 {
	echo -e "\n8.  Is max-depth working as expected?"
	"$f_STAT_WATCH" "$v_PROGRAMDIR"/testing -i <( echo "Max-depth 0" ) --output "$v_PROGRAMDIR"/testing2/report1.txt
	if [[ $( egrep -c "^Maximum depth reached at" "$v_PROGRAMDIR"/testing2/report1.txt ) -ne 1 ]]; then
		fn_fail "8.1"
	fi
	fn_pass "8.1"
	if [[ $( egrep -c "subdir/" "$v_PROGRAMDIR"/testing2/report1.txt ) -ne 0 ]]; then
		fn_fail "8.2"
	fi
	fn_pass "8.2"
	sleep 1.1
	"$f_STAT_WATCH" "$v_PROGRAMDIR"/testing -i <( echo "Max-depth 0" ) --output "$v_PROGRAMDIR"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | egrep -c "DIRECTORIES TOO DEEP TO PROCESS" ) -ne 0 ]]; then
		### We don't want it reporting that if there are no other differences
		fn_fail "8.3"
	fi
	fn_pass "8.3"
	sleep 1.1
	mkdir -p "$v_PROGRAMDIR/testing/subdir2"
	"$f_STAT_WATCH" "$v_PROGRAMDIR"/testing -i <( echo "Max-depth 0" ) --output "$v_PROGRAMDIR"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report2.txt "$v_PROGRAMDIR"/testing2/report1.txt | egrep -A2 "DIRECTORIES TOO DEEP TO PROCESS" | egrep -c "testing/subdir" ) -ne 2 ]]; then
		fn_fail "8.4"
	fi
	fn_pass "8.4"
}

function fn_test_9 {
	echo -e "\n9.  Do the backups work as expected with \"--diff\""
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report2.txt
	"$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt --backup -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackup+ $v_PROGRAMDIR/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 1 ]]; then
		fn_fail "9.1"
	fi
	fn_pass "9.1"
	"$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt --backup -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackup+ $v_PROGRAMDIR/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456.php_[0-9]+$" ) -ne 1 ]]; then
		### There were no changes to this file, so a second backup should not have been made
		fn_fail "9.2"
	fi
	fn_pass "9.2"
	sleep 1.1
	fn_make_files_1
	"$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt --backup -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackup+ $v_PROGRAMDIR/testing/123Ͼ456.php" ) > /dev/null
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "123Ͼ456\.php_[0-9]+$" ) -ne 2 ]]; then
		fn_fail "9.3"
	fi
	fn_pass "9.3"
	fn_remove_files
	fn_make_files_1
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	sleep 1.1
	fn_change_files_1
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report2.txt
	"$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt --backup -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "\.php_[0-9]+$" ) -ne 7 ]]; then
		fn_fail "9.4"
	fi
	fn_pass "9.4"
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 && $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/subdir | egrep -c "abc\.txt_[0-9]+$" ) -ne 0 ]]; then
		fn_fail "9.5"
	fi
	fn_pass "9.5"
	sleep 1.1
	echo "1236" > "$v_PROGRAMDIR/testing/123?456.php"
	echo "1236" > "$v_PROGRAMDIR/testing/123!456.php"
	echo "1236" > "$v_PROGRAMDIR/testing/123Ͼ456.php"
	mv -f "$v_PROGRAMDIR"/testing2/report2.txt "$v_PROGRAMDIR"/testing2/report1.txt
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report2.txt
	"$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt --backup -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackupR \.php$" ) > /dev/null
	if [[ $( \ls -1 "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"/testing | egrep -c "\.php_[0-9]+$" ) -ne 10 ]]; then
		fn_fail "9.6"
	fi
	fn_pass "9.6"
}

function fn_test_10 {
	echo -e "\n10. If there are backed-up files, does \"--list\" work as anticipated?"
	if [[ $( "$f_STAT_WATCH" --list "$v_PROGRAMDIR/"'testing/123?456.php' | fgrep -c "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"'/testing/123?456.php' ) -ne 2 ]]; then
		fn_fail "10.1"
	fi
	fn_pass "10.1"
	if [[ $( "$f_STAT_WATCH" --list "$v_PROGRAMDIR/"/testing/subdir/abc.txt | fgrep -c "There are no backups of this file" ) -ne 1 ]]; then
		fn_fail "10.2"
	fi
	fn_pass "10.2"
	"$f_STAT_WATCH" --backup "$v_PROGRAMDIR"/testing2/report2.txt -i <( echo -e "BackupD $v_PROGRAMDIR/testing2/backup\nBackupR ." )
	if [[ $( "$f_STAT_WATCH" --list "$v_PROGRAMDIR"/testing/subdir/abc.txt | fgrep -c "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR"'/testing/subdir/abc.txt' ) -ne 1 ]]; then
		fn_fail "10.3"
	fi
	fn_pass "10.3"
	if [[ $( "$f_STAT_WATCH" --list "$v_PROGRAMDIR"'/testing/123.php'\'' -- d' | egrep -c "$v_PROGRAMDIR"/testing2/backup"$v_PROGRAMDIR""/testing/123.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "10.4"
	fi
	fn_pass "10.4"
}

function fn_test_11 {
	echo -e "\n11. With \"--diff\" Is a change to each of the stats correctly identified"
	"$f_STAT_WATCH" --record "$v_PROGRAMDIR"/testing --output "$v_PROGRAMDIR"/testing2/report1.txt
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- )[-drwx]{10}/\1drwxrwxrwx/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.1"
	fi
	fn_pass "11.1"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- )[0-9]+/\199999/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.2"
	fi
	fn_pass "11.2"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- )[0-9]+/\199999/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.3"
	fi
	fn_pass "11.3"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- )[0-9]+/\16/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES THAT CHANGED IN SIZE" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.4"
	fi
	fn_pass "11.4"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- [0-9]+ -- )[-0-9:. ]{35} -- /\11997-03-19 22:41:00.958366395 -0400 -- /" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.5"
	fi
	fn_pass "11.5"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- [0-9]+ -- [-0-9:. ]{35} -- )[-0-9:. ]{35}/\11997-03-19 22:41:00.000000000 -0400/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.6"
	fi
	fn_pass "11.6"
	cp -af "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- .*)$/\1 -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab/" testing2/report1.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$v_PROGRAMDIR"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- .*)$/\1 -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/" testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$v_PROGRAMDIR"/testing2/report1.txt "$v_PROGRAMDIR"/testing2/report2.txt | fgrep -A1 "FILES WITH A DIFFERENT SIZE OR MD5 SUM" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.7"
	fi
	fn_pass "11.7"
}

function fn_test_12 {
	echo -e "\n12. Is backup pruning working as anticipated?"
}

function fn_test_13 {
	echo -e "\n13. Is logging working as anticipated?"
}

function fn_test_14 {
	echo -e "\n14. Is the \"--ignore-on-record\" functionality working as anticipated?"
}

function fn_test_15 {
	echo -e "\n15. Does ignoring work as anticipated (\"--ignore\" flag, bare string in the job file, \"*\" and \"R\" control strings"
}

function fn_test_16 {
	echo -e "\n16. Does the \"--no-check-retention\" flag work as expected?"
}

function fn_test_17 {
	echo -e "\n17. Do the \"--no-ctime\" and \"--no-partial-seconds\" flags work as expected?"
}

function fn_test_18 {
	echo -e "\n18. Do the \"I\" and \"Include\" control strings work as expected?"
}

function fn_test_19 {
	echo -e "\n19. Do the \"Time-\" and \"MD5R\" control strings work as expected?"
}

##### I'm pretty sure that if there isn't read access to a file and we ask for an md5sum, it will fail. Should test this
##### Need to test against various permissions for directories and how they impact both statting them and getting the list of files within them

fn_remove_files
fn_make_files_1
fn_test_1
fn_test_2
fn_test_3
fn_test_4
fn_remove_files
fn_make_files_1
fn_test_5
fn_test_6
fn_remove_files
fn_make_files_1
fn_test_7
fn_test_8
fn_remove_files
fn_make_files_1
fn_test_9
fn_test_10
fn_remove_files
fn_make_files_1
fn_test_11
fn_remove_files
fn_test_12
fn_test_13
fn_test_14
fn_test_15
fn_test_16
fn_test_17
fn_test_18
fn_test_19






















