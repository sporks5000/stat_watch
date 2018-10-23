#! /bin/bash

function fn_make_pointers {
	### Create a backup of a file
	echo -n "ORIGINAL CONTENT" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	chmod 644 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	### Find the stamp of that backup
	v_STAMP1="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep -o "_[0-9]+$" )"
	### Change permissions and make another packup with the same content so that the first will be a pointer
	chmod 600 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	### Find the stamp of that backup
	v_STAMP2="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep -v "$v_STAMP1" | egrep -o "_[0-9]+$" )"
	### Change permissions again in order to make the second backup a pointer
	chmod 611 "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	### Get it's stamp too
	v_STAMP3="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep -v "$v_STAMP1|$v_STAMP2" | egrep -o "_[0-9]+$" )"
	### Create three more backups
	echo -n "SASQUATCH" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_STAMP4="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep -v "$v_STAMP1|$v_STAMP2|$v_STAMP3" | egrep -o "_[0-9]+$" )"
	echo -n "SASQUATCH TORNADO" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	v_STAMP5="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep -v "$v_STAMP1|$v_STAMP2|$v_STAMP3|$v_STAMP4" | egrep -o "_[0-9]+$" )"
	echo -n "SASQUATCH TORNADO REVENGE" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### Hold the first and second backups
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_STAMP1" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	"$f_STAT_WATCH" --config "$f_CONF" --hold "$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_STAMP2" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### Rename the third backup to change its stamp to five days ago
	v_POINT3="$( date --date="now - 5 days" +%s )9"
	v_NEW_STAMP3="_${v_POINT3}"
	for i in $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep "$v_STAMP3" ); do
		v_EXT="$( echo "$i" | egrep -o "_[a-z5]+$" )"
		mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/""$i" "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP3""$v_EXT"
	done

	### Rename the second to six days ago, point it at the third backup
	v_POINT2="$( date --date="now - 6 days" +%s )8"
	v_NEW_STAMP2="_${v_POINT2}"
	for i in $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep "$v_STAMP2" ); do
		v_EXT="$( echo "$i" | egrep -o "_[a-z5]+$" )"
		mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/""$i" "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2""$v_EXT"
		if [[ -z "$v_EXT" || "$v_EXT" == "_pointer" ]]; then
			echo -n "$v_POINT3" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2""$v_EXT"
		fi
	done

	### Rename the first backup to place its stamp seven days ago, point it at the second backup
	v_POINT1="$( date --date="now - 7 days" +%s )7"
	v_NEW_STAMP1="_${v_POINT1}"
	for i in $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep "$v_STAMP1" ); do
		v_EXT="$( echo "$i" | egrep -o "_[a-z5]+$" )"
		mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/""$i" "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1""$v_EXT"
		if [[ -z "$v_EXT" || "$v_EXT" == "_pointer" ]]; then
			echo -n "$v_POINT2" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1""$v_EXT"
		fi
	done
}

function fn_test_30_1 {
	echo "30.1. Verify held pointer backups are not at risk for their content rotating out"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Setup the backups as we want them
	fn_make_pointers

	### Prune the backups to leave 3 copies and 3 days
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 3 --backup-md 3

	### Verify that the file that used to hold the content is now gone:
	if [[ -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP3" ]]; then
		fn_fail "30.1.1"
	fi
	fn_pass "30.1.1"

	### Did the content end up with the newest of those backups
	if [[ -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"_pointer ]]; then
		fn_fail "30.1.2.1"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2" )" != "ORIGINAL CONTENT" ]]; then
		fn_fail "30.1.2.2"
	fi
	fn_pass "30.1.2"

	### Does the oldest backup correctly point to the content
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"_pointer )" != "$v_NEW_STAMP2" ]]; then
		fn_fail "30.1.3.1"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1" )" == "ORIGINAL CONTENT" ]]; then
		fn_fail "30.1.3.2"
	fi
	fn_pass "30.1.3"
}

function fn_test_30_2 {
	echo "30.1. Verify held pointer backups are not at risk for their content rotating out, even with complicated pointer chains"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Setup the backups as we want them
	fn_make_pointers

	### Restore the second backup
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	### Now restore one of the other backups
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_STAMP5" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	### And NOW restore the first backup
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --restore "$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### At this point, the second backup should point to the newest file with a pointer (6th), and the first backup should point to the newest file (10th)
	# v_STAMP6="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | sort | egrep -o "_[0-9]+_pointer$" | egrep -o "_[0-9]+" | tail -n1 )"
	v_STAMP10="$( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | sort | egrep -o "_[0-9]+$" | tail -n1 )"

	### Test if 2 points to 6, 1 points to 10, and 6 points to 10
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"_pointer )" != "$v_STAMP10" ]]; then
		fn_fail "30.2.1.1"
	fi
	v_STAMP6="_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"_pointer )"
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_STAMP6"_pointer )" != "$v_STAMP10" ]]; then
		fn_fail "30.2.1.2"
	fi
	fn_pass "30.2.1"

	### Right now, the weak link is the sixth backup. If it is removed, the second backup (held) needs to still point to content (the tenth backup)

	### Create three more backups
	echo -n "SASQUATCH" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	echo -n "SASQUATCH TORNADO" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup
	echo -n "SASQUATCH TORNADO REVENGE" > "$d_STATWATCH_TESTS_WORKING/testing/123.php"
	"$f_STAT_WATCH" --config "$f_CONF" --backup-file "$d_STATWATCH_TESTS_WORKING/testing/123.php" --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup

	### Move the sixth backup so that it was four days ago
	v_POINT6="$( date --date="now - 4 days" +%s )0"
	v_NEW_STAMP6="_${v_POINT6}"
	for i in $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep "$v_STAMP6" ); do
		v_EXT="$( echo "$i" | egrep -o "_[a-z5]+$" )"
		mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/""$i" "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP6""$v_EXT"
	done
	### Move the tenth backup so that it was three days ago
	v_POINT10="$( date --date="now - 3 days" +%s )0"
	v_NEW_STAMP10="_${v_POINT10}"
	for i in $( \ls -1 "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/" | egrep "$v_STAMP10" ); do
		v_EXT="$( echo "$i" | egrep -o "_[a-z5]+$" )"
		mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/""$i" "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP10""$v_EXT"
	done

	### Adjust the pointers for the first backup so that they point to the new 10th
	echo -n "$v_POINT10" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"
	echo -n "$v_POINT10" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"_pointer
	### Adjust the pointers for the second backup so that they point to the new 6th
	echo -n "$v_POINT6" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"
	echo -n "$v_POINT6" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"_pointer
	### Adjust the pointers for the 6th backup so that they point to the new 10th
	echo -n "$v_POINT10" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP6"
	echo -n "$v_POINT10" > "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP6"_pointer

	### Make a copy of the backup directory
	cp -a "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing" "$d_STATWATCH_TESTS_WORKING"/testing2/backup_copy

	### Test pruning backups older than 4 days
	sleep 1.1
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 3 --backup-md 4

	### verify that the sixth backup is gone and the tenth backup is still there
	if [[ -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP6" ]]; then
		fn_fail "30.2.2.1"
	fi
	if [[ ! -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP10" ]]; then
		fn_fail "30.2.2.2"
	fi
	fn_pass "30.2.2"

	### Make sure that the first and second backup points to the still present 10th backup, and that the 10th backup has the content
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"_pointer )" != "$v_NEW_STAMP10" ]]; then
		fn_fail "30.2.3.1"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2" )" == "ORIGINAL CONTENT" ]]; then
		fn_fail "30.2.3.2"
	fi
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"_pointer )" != "$v_NEW_STAMP10" ]]; then
		fn_fail "30.2.3.3"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1" )" == "ORIGINAL CONTENT" ]]; then
		fn_fail "30.2.3.4"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP10" )" != "ORIGINAL CONTENT" ]]; then
		fn_fail "30.2.3.5"
	fi
	fn_pass "30.2.3"

	### Now again, but pruning backups older than 3 days (thus losing where the content currently is)
	rm -rf "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing"
	mv -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup_copy "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing"
	"$f_STAT_WATCH" --config "$f_CONF" --prune --backupd "$d_STATWATCH_TESTS_WORKING"/testing2/backup --backup-mc 3 --backup-md 3

	### Verify that the file that used to hold the content is now gone:
	if [[ -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP6" ]]; then
		fn_fail "30.2.4"
	fi
	fn_pass "30.2.4"

	### Did the content end up with the newest of those backups
	if [[ -f "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2"_pointer ]]; then
		fn_fail "30.2.5.1"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP2" )" != "ORIGINAL CONTENT" ]]; then
		fn_fail "30.2.5.2"
	fi
	fn_pass "30.2.5"

	### Does the oldest backup correctly point to the content
	if [[ "_$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1"_pointer )" != "$v_NEW_STAMP2" ]]; then
		fn_fail "30.2.6.1"
	fi
	if [[ "$( cat "$d_STATWATCH_TESTS_WORKING"/testing2/backup"$d_STATWATCH_TESTS_WORKING/testing/123.php""$v_NEW_STAMP1" )" == "ORIGINAL CONTENT" ]]; then
		fn_fail "30.2.6.2"
	fi
	fn_pass "30.2.6"
}

fn_test_30_1 "$@"
rm -rf "$d_STATWATCH_TESTS_WORKING"
fn_test_30_2 "$@"
