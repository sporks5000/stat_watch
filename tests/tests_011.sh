#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_11 {
	echo -e "\n11. With \"--diff\" Is a change to each of the stats correctly identified"
	"$f_STAT_WATCH" --record "$d_STATWATCH_TESTS_WORKING"/testing --output "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- )[-drwx]{10}/\1drwxrwxrwx/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.1"
	fi
	fn_pass "11.1"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- )[0-9]+/\199999/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.2"
	fi
	fn_pass "11.2"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- )[0-9]+/\199999/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO PERMISSIONS OR OWNER" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.3"
	fi
	fn_pass "11.3"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- )[0-9]+/\16/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES THAT CHANGED IN SIZE" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.4"
	fi
	fn_pass "11.4"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- [0-9]+ -- )[-0-9:. ]{35} -- /\11997-03-19 22:41:00.958366395 -0400 -- /" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.5"
	fi
	fn_pass "11.5"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- [-drwx]{10} -- [0-9]+ -- [0-9]+ -- [0-9]+ -- [-0-9:. ]{35} -- )[-0-9:. ]{35}/\11997-03-19 22:41:00.000000000 -0400/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH CHANGES TO M-TIME OR C-TIME" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.6"
	fi
	fn_pass "11.6"
	cp -af "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- .*)$/\1 -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab/" "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt
	sed -i -E "s/(^Processing: .* - )[0-9]+$/\1123456789/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	sed -i -E "s/(123\.php' -- d' -- .*)$/\1 -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/" "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt
	if [[ $( "$f_STAT_WATCH" --diff "$d_STATWATCH_TESTS_WORKING"/testing2/report1.txt "$d_STATWATCH_TESTS_WORKING"/testing2/report2.txt | fgrep -A1 "FILES WITH A DIFFERENT SIZE OR MD5 SUM" | egrep -c "123\.php'.'' -- d" ) -ne 1 ]]; then
		fn_fail "11.7"
	fi
	fn_pass "11.7"
}

fn_make_files_1
fn_test_11
