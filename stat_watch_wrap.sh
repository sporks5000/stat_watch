#! /bin/bash
### A wrapper script for stat_watch.pl
### Created by ACWilliams

export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

### Find out where we are and make sure that stat_watch.pl is here too
d_PROGRAM='####INSTALLATION_DIRECTORY####'
f_PROGRAM="stat_watch_wrap.sh"

function fn_locate {
	f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" )"
	if [[ -z $f_PROGRAM ]]; then
		f_PROGRAM="${BASH_SOURCE[0]}"
	fi
	d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && pwd )"
	f_PROGRAM="$( basename "$f_PROGRAM" )"
}

if [[ ${d_PROGRAM:0:1} != "/" ]]; then
	fn_locate
else
	### If any of the arguments say that we can't trust the hard-coded location, find it manually
	a_CL_ARGUMENTS=( "$@" )
	for (( c=0; c<=$(( ${#a_CL_ARGUMENTS[@]} - 1 )); c++ )); do
		v_ARG="${a_CL_ARGUMENTS[$c]}"
		if [[ "$v_ARG" == "--locate" ]]; then
			fn_locate
			break
		fi
	done
fi

### Pull in utility functions
source "$d_PROGRAM"/includes/util.shf

f_PERL_SCRIPT="stat_watch.pl"
d_WORKING="$d_PROGRAM"/.stat_watch

### Read from the configuration
source "$d_PROGRAM"/includes/variables.shf
if [[ "$1" == "--config" ]]; then
	shift
	v_CONFIG="$1"
	shift
	fn_read_conf "$v_CONFIG"
else
	fn_check_conf	
fi
fn_perl_args

f_JOBS="$d_WORKING"/wrap_jobs_created

### If any of the arguments are asking for help, output help and exit
a_CL_ARGUMENTS=( "$@" )
for (( c=0; c<=$(( ${#a_CL_ARGUMENTS[@]} - 1 )); c++ )); do
	v_ARG="${a_CL_ARGUMENTS[$c]}"
	if [[ "$v_ARG" == "-h" || "$v_ARG" == "--help" ]]; then
		if [[ "${a_CL_ARGUMENTS[$c + 1]}" == "--locate" ]]; then
			c=$(( c + 1 ));
		fi
		if [[ "${a_CL_ARGUMENTS[$c + 1]}" == "use-cases" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_usage.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "flags" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_flags.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "job" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_job_file.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "backups" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_backups.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "job-files" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_job_files.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "files" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_files.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "tests" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_tests.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "assume" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_assume.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "conf" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_conf.txt "$d_PROGRAM"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "db_watch" ]]; then
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_db_watch.txt "$d_PROGRAM"/texts/help_feedback.txt
		else
			"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_basic.txt "$d_PROGRAM"/texts/help_feedback.txt
		fi
		exit
	elif [[ "$v_ARG" == "--version" ]]; then
		"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/version.txt
		exit
	fi
done

### Test to ensure that the necessary perl modules are present
if [[ ! -f "$d_WORKING"/perl_modules ]]; then
	v_MODULES=''
	for i in "Digest::MD5" "Digest::MD5::File" "Cwd" "POSIX" "Fcntl"; do
		if [[ $( "$v_PERL" -e "use $i;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
			v_MODULES="$v_MODULES $i"
		fi
	done
	if [[ -n $v_MODULES ]]; then
		echo
		echo "Attempting to install the necessary perl modules"
		echo
		sleep 2
		"$v_CPAN" -i $v_MODULES
		if [[ $? -ne 0 ]]; then
			echo "Failed to install perl modules" > /dev/stderr
			echo "It should be possible to install these with the following command:" > /dev/stderr
			echo "    '$v_CPAN' -i $v_MODULES" > /dev/stderr
			exit
		fi
		echo
	else
		mkdir -p "$d_WORKING"
		touch "$d_WORKING"/perl_modules
	fi
fi

if [[ "$1" == "--run" ]]; then
### Here's the part for if we're running a job
	source "$d_PROGRAM"/includes/run.shf
	shift
	if [[ "$1" == "--locate" ]]; then
		shift
	fi
	if [[ -n "$1" && "$1" != "--errors" || -n "$2" ]]; then
		fn_run "$@"
	else
		source "$d_PROGRAM"/includes/assume.shf
		f_ASSUME="$( fn_find_pwd )"
		fn_run "$f_ASSUME" "$@"
	fi
elif [[ "$1" == "--email-test" ]]; then
	source "$d_PROGRAM"/includes/email_test.shf
	shift
	if [[ "$1" == "--locate" ]]; then
		shift
	fi
	fn_email_test "$@"
elif [[ "$1" == "--assume" ]]; then
	source "$d_PROGRAM"/includes/assume.shf
	shift
	if [[ "$1" == "--locate" ]]; then
		shift
	fi
	fn_create_assumption "$@"
elif [[ -n "$1" && "$1" != "--create" ]]; then
### This covers all of the flags that need to be ran by the perl script
	source "$d_PROGRAM"/includes/assume.shf
	f_ASSUME="$( fn_find_pwd )"

	b_ADD_INCLUDE=true
	if [[ -n "$f_ASSUME" ]]; then
		fn_assume_include "$@"
	fi

	if [[ "$b_ADD_INCLUDE" == true ]]; then
		"$v_PERL" "$d_PROGRAM"/"$f_PERL_SCRIPT" "${a_PERL_ARGS[@]}" "$@" --include "$f_ASSUME"
	else
		"$v_PERL" "$d_PROGRAM"/"$f_PERL_SCRIPT" "${a_PERL_ARGS[@]}" "$@"
	fi
elif [[ "$1" == "--create" ]]; then
	if [[ "$1" == "--create" ]]; then
		shift
	fi
	if [[ "$1" == "--locate" ]]; then
		shift
	fi
	source "$d_PROGRAM"/includes/create.shf
	fn_create
else
	"$d_PROGRAM"/scripts/fold_out.pl "$d_PROGRAM"/texts/help_header.txt "$d_PROGRAM"/texts/help_basic.txt "$d_PROGRAM"/texts/help_feedback.txt
fi


