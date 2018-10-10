#! /bin/bash

function fn_test_21 {
	echo "21. If a directory is included specifically but otherwise would be ignored, is it processed as anticipated?"
	### All directories listed at the command line or with the control string "I" are added to the global array "@v_dirs"
		### Note: "@v_dirs" is used elsewhere in the script in local scopes. We are only concerned about the global here
	### Every time a new listed directory is processed the subroutine "fn_check_strings" is run against it to verify that we remove any rules that would exclude it
	### "fn_check_strings" checks the directory against "@v_ignore", "@v_rignore", and "@v_star_ignore" to create "@v_temp_ignore", "@v_temp_rignore", and "@v_temp_star_ignore"
	### The three temp arrays are used in the subroutine "fn_check_file" to verify that files don't match any of these
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1
	fn_make_files_2

	### Verify that it's skipping files correctly
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --ignore "$d_STATWATCH_TESTS_WORKING"/testing/subdir2
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne 0 ]]; then
		fn_fail "21.1"
	fi
	fn_pass "21.1"

	### Make sure that the files within the directory we want are not being skipped
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing "$d_STATWATCH_TESTS_WORKING"/testing/subdir2/subdir4 --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt --ignore "$d_STATWATCH_TESTS_WORKING"/testing/subdir2
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne "2" ]]; then
		fn_fail "21.2"
	fi
	fn_pass "21.2"

	### What if they're included in a job file
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing "$d_STATWATCH_TESTS_WORKING"/testing/subdir2/subdir4 --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt -i <( echo "$d_STATWATCH_TESTS_WORKING"/testing/subdir2 )
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne "2" ]]; then
		fn_fail "21.3"
	fi
	fn_pass "21.3"

	### What if we're using "*"
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing "$d_STATWATCH_TESTS_WORKING"/testing/subdir2/subdir4 --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt -i <( echo "* $d_STATWATCH_TESTS_WORKING"/testing/subdir )
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne "2" ]]; then
		fn_fail "21.4"
	fi
	fn_pass "21.4"

	### What if we're using "R"
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing "$d_STATWATCH_TESTS_WORKING"/testing/subdir2/subdir4 --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt -i <( echo "R subdir" )
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne "2" ]]; then
		fn_fail "21.5"
	fi
	fn_pass "21.5"

	### And another
	"$f_STAT_WATCH" --config "$f_CONF" --record "$d_STATWATCH_TESTS_WORKING"/testing "$d_STATWATCH_TESTS_WORKING"/testing/subdir2/subdir4 --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt -i <( echo "R testing" )
	if [[ $( egrep "subdir2" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt | egrep -cv "Processing:" ) -ne "6" ]]; then
		fn_fail "21.6"
	fi
	fn_pass "21.6"
}

fn_test_21 "$@"
