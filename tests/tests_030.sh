#! /bin/bash

function fn_test_30 {
	echo "30. Verify held pointer backups are not at risk for their content rotating out"
	if [[ "$1" == "--list" ]]; then
		return
	fi
	source "$d_STATWATCH_TESTS"/tests_include.shf
	fn_make_files_1

	### Given a held pointer backup whose content is about to be pruned, is the content successfully kept?
	### Given two held pointer backups whose content is about to be pruned, Does the content end up with the newest of them?
	### Given two held pointer backups whose content is about to be pruned, does the oldest end up correctly pointing to the newest

}

fn_test_30 "$@"
