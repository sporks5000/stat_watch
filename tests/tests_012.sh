#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

echo "This file is just here to remind me that there are still tests that I want to impliment"

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

##### I'm pretty sure that if there isn't read access to a file and we ask for an md5sum, it will fail. Should test this under test 7
##### Need to test against various permissions for directories and how they impact both statting them and getting the list of files within them

fn_make_files_1
fn_test_12
fn_test_13
fn_test_14
fn_test_15
fn_test_16
fn_test_17
fn_test_18
fn_test_19
