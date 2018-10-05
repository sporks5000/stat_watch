#! /bin/bash

source "$d_STATWATCH_TESTS"/tests_include.shf

function fn_test_12 {
	echo -e "\n12. Is backup pruning working as anticipated (including \"_hold\" functionality)?"
	### There are two ways that backups are pruned: when the "--prune" flag is used, and when a backup of a file is made during "--diff" (assuming "--no-check-retention" was not used)
	### Backups are pruned within the "fn_check_retention" subroutine
	### When backups are pruned is controled by the $v_retention_max_copies variable and the $v_retention_min_days variable
	### $v_retention_max_copies defaults to 4 and is set by the "BackupMC" control string.
	### $v_retention_min_days defaults to 7 and is set by the "BackupMD" control string
	### The desired behavior is: If there are more than $v_retention_max_copies backups of a file, all of the copies older than $v_retention_min_days days will be removed
		### Thus if $v_retention_max_copies is 4, and there are 12 backups present, but all of them are younger than $v_retention_min_days days, none of them are removed
	### Backups should not be removed if they have a "_hold" file
	### Whether or not backups are being taken was already tested in 006 and 009
}

fn_make_files_1
fn_test_12
