#! /bin/bash

#====================================#
#== Initial Variables and Settings ==#
#====================================#

set -e

export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
b_LIST=false

### Find where statwatch is
export d_PROGRAM='####INSTALLATION_DIRECTORY####'
if [[ "${d_PROGRAM:0:1}" != "/" ]]; then
	f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" || true )"
	if [[ -z "$f_PROGRAM" ]]; then
		f_PROGRAM="${BASH_SOURCE[0]}"
	fi
	d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && cd -P .. && pwd )"
	if [[ -f "$d_PROGRAM"/stat_watch.pl && -f "$d_PROGRAM"/stat_watch_wrap.sh ]]; then
		export d_PROGRAM="$d_PROGRAM"
	else
		echo "Cannot find the installation directory. Exiting"
		exit 1
	fi
fi

### Find the testing and working directories
export d_PROGRAM_TESTS="$d_PROGRAM"/tests
export d_PROGRAM_TESTS_WORKING="$d_PROGRAM_TESTS"/working

b_SPECIFIC=false

### If any of the arguments are asking for help, output help and exit
a_ARGS=( "$@" )
for (( c=0; c<=$(( ${#a_ARGS[@]} - 1 )); c++ )); do
	v_ARG="${a_ARGS[$c]}"
	if [[ "$v_ARG" == "-h" || "$v_ARG" == "--help" ]]; then
		"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_tests.txt "$d_PROGRAM"/texts/help_feedback.txt
		exit
	fi
done

#===============#
#== Functions ==#
#===============#

function fn_run_test {
	local f_TEST=
	### Make sure that we have everything in place necessary to run a test
	if [[ -n "$1" && -n $d_PROGRAM && -n "$d_PROGRAM_TESTS" && -n "$d_PROGRAM_TESTS_WORKING" ]]; then
		f_TEST="$1"
	else
		echo "Test file does not exist or required variables not set" > /dev/stderr
		fn_unskip
		exit 1
	fi

	### Destroy and create the working directory
	if [[ -d "$d_PROGRAM_TESTS_WORKING" ]]; then
		rm -rf "$d_PROGRAM_TESTS_WORKING"
	fi
	mkdir "$d_PROGRAM_TESTS_WORKING"

	### Make the test executable
	if [[ ! -x "$d_PROGRAM_TESTS"/"$f_TEST" ]]; then
		chmod +x "$d_PROGRAM_TESTS"/"$f_TEST"
	fi

	### Run the test script
	if [[ "$b_LIST" == false ]]; then
		local v_SUCCESS=true
		echo -e "\e[34mRunning tests from file '$f_TEST'\e[00m"
		"$d_PROGRAM_TESTS"/"$f_TEST" || v_SUCCESS=false
	else
		echo -e "\e[34mListing tests from file '$f_TEST'\e[00m"
		"$d_PROGRAM_TESTS"/"$f_TEST" --list
	fi

	### Make the test no longer executable
	chmod -x "$d_PROGRAM_TESTS"/"$f_TEST"

	### Exit if the test failed
	if [[ "$b_LIST" == false ]]; then
		if [[ "$v_SUCCESS" == false ]]; then
			### If the script failed, exit
			echo -e "\e[31mTests from file '$f_TEST': Failed\e[00m" > /dev/stderr
			if [[ "$b_SPECIFIC" == false ]]; then
				echo -e "To skip these tests, add the flags '--skip $f_TEST'"
			fi
			echo
			fn_unskip 
			exit 1
		fi
		echo -e '\e[32mTests from file '$f_TEST': Success!\e[00m\n'
	fi
}

function fn_pre_post_test {
### Run the pre and post scripts
### $1 is "pre" or "post"
	local v_PRE_POST="$1"
	if [[ -f "$d_PROGRAM_TESTS"/tests_"$v_PRE_POST".sh ]]; then
		### Run the pre test file if one exists
		local v_SUCCESS=true
		chmod +x "$d_PROGRAM_TESTS"/tests_"$v_PRE_POST".sh
		"$d_PROGRAM_TESTS"/tests_"$v_PRE_POST".sh || v_SUCCESS=false
		chmod -x "$d_PROGRAM_TESTS"/tests_"$v_PRE_POST".sh
		if [[ "$v_SUCCESS" == false ]]; then
			echo -e "\e[31mThe ${v_PRE_POST}-test script failed\e[00m" > /dev/stderr
			echo
			fn_unskip 
			exit 1
		fi
	fi
}

function fn_unskip {
### Reset test file anmes so that they are no longer skipped
	local v_NAME=
	for i in $( ls -1 "$d_PROGRAM_TESTS" | grep -E "^skipped_tests_[0-9_]+\.[^.]+$" ); do
		v_NAME="$( echo "$i" | sed "s/^skipped_//" )"
		mv -f "$d_PROGRAM_TESTS"/"$i" "$d_PROGRAM_TESTS"/"$v_NAME"
	done
}

#=====================#
#== Parse Arguments ==#
#=====================#

source "$d_PROGRAM"/includes/util.shf

fn_unskip
if [[ "$1" == "--list" ]]; then
	b_LIST=true
	shift
fi
if [[ -n "$1" && "$1" != "--skip" && "$1" != "--start" ]]; then
### Run a single test script
	b_SPECIFIC=true
	fn_pre_post_test "pre"
	while [[ -n "$1" ]]; do
		fn_file_path "$1"
		if [[ -f "$d_PROGRAM_TESTS"/"$s_FILE" ]]; then
			fn_run_test "$s_FILE"
		else
			v_FILE="$( \ls -1 "$d_PROGRAM_TESTS" | grep -E -m1 "^tests_$1\." )"
			if [[ -n "$v_FILE" ]]; then
				fn_run_test "$v_FILE"
			fi
		fi
		shift
	done
	fn_pre_post_test "post"
else
	### Skip any tests that were specified to be skipped
	v_START=
	if [[ "$1" == "--start" ]]; then
		shift
		fn_file_path "$1"
		if [[ -f "$d_PROGRAM_TESTS"/"$s_FILE" ]]; then
			v_START="$s_FILE"
		else
			v_FILE="$( \ls -1 "$d_PROGRAM_TESTS" | grep -E -m1 "^tests_$1\." )"
			if [[ -n "$v_FILE" ]]; then
				v_START="$v_FILE"
			fi
		fi
		shift
	fi
	if [[ "$1" == "--skip" ]]; then
		shift
		while [[ -n "$1" ]]; do
			fn_file_path "$1"
			if [[ -f "$d_PROGRAM_TESTS"/"$s_FILE" && $( echo "$s_FILE" | grep -Ec "^tests_[0-9_]+\.[^.]+$" ) -gt 0 ]]; then
				mv -f "$d_PROGRAM_TESTS"/"$s_FILE" "$d_PROGRAM_TESTS"/skipped_"$s_FILE"
			else
				v_FILE="$( \ls -1 "$d_PROGRAM_TESTS" | egrep -m1 "^tests_$1\." )"
				if [[ -n "$v_FILE" && $( echo "$v_FILE" | grep -Ec "^tests_[0-9_]+\.[^.]+$" ) -gt 0 ]]; then
					mv -f "$d_PROGRAM_TESTS"/"$v_FILE" "$d_PROGRAM_TESTS"/skipped_"$v_FILE"
				fi
			fi
			shift
		done
	fi

	### Iterate through all of the test scripts
	if [[ $( ls -1 "$d_PROGRAM_TESTS" | sort -n | grep -Ec "^tests_[0-9_]+\.[^.]+$" ) -gt 0 ]]; then
		fn_pre_post_test "pre"
		for i in $( ls -1 "$d_PROGRAM_TESTS" | sort -n | grep -E "^tests_[0-9_]+\.[^.]+$" ); do
			if [[ -z "$v_START" || "$v_START" == "$i" ]]; then
				fn_run_test "$i"
				v_START=
			fi
		done
		fn_pre_post_test "post"
	else
		echo "No tests found"
	fi
fi

if [[ -n "$d_PROGRAM_TESTS_WORKING" ]]; then
	rm -rf "$d_PROGRAM_TESTS_WORKING"
fi
exit 0
