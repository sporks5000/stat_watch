#! /bin/bash
### A wrapper script for stat_watch.pl
### Created by ACWilliams

export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

### Find out where we are and make sure that stat_watch.pl is here too
d_PROGRAM="####INSTALLATION_DIRECTORY####"
f_PROGRAM="stat_watch_wrap.sh"

if [[ ${d_PROGRAM:0:1} != "/" ]]; then
	f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" )"
	if [[ -z $f_PROGRAM ]]; then
		f_PROGRAM="${BASH_SOURCE[0]}"
	fi
	d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && pwd )"
	f_PROGRAM="$( basename "$f_PROGRAM" )"
fi

f_PERL_SCRIPT="stat_watch.pl"
d_WORKING="stat_watch"
f_JOBS="$d_PROGRAM"/."$d_WORKING"/wrap_jobs_created

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

### If any of the arguments are asking for help, output help and exit
a_CL_ARGUMENTS=( "$@" )
for (( c=0; c<=$(( ${#a_CL_ARGUMENTS[@]} - 1 )); c++ )); do
	v_ARG="${a_CL_ARGUMENTS[$c]}"
	if [[ "$v_ARG" == "-h" || "$v_ARG" == "--help" ]]; then
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
if [[ ! -f "$d_PROGRAM"/."$d_WORKING"/perl_modules ]]; then
	v_MODULES=''
	for i in "Digest::MD5" "Digest::MD5::File" "Cwd" "POSIX"; do
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
		touch "$d_PROGRAM"/."$d_WORKING"/perl_modules
	fi
fi

if [[ "$1" == "--run" ]]; then
### Here's the part for if we're running a job
	source "$d_PROGRAM"/includes/run.shf
	shift
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
	fn_email_test "$@"
elif [[ "$1" == "--assume" ]]; then
	source "$d_PROGRAM"/includes/assume.shf
	shift
	fn_create_assumption "$@"
elif [[ "$1" == "--record" || "$1" == "--links" || "$1" == "--new-lines" || "$1" == "--diff" || "$1" == "--" || "$1" == "--backup" || "$1" == "--list" || "$1" == "--prune" || "$1" == "--md5-test" || "$1" == "--backup-file" || ( -n "$1" && "${1:0:2}" != "--" ) ]]; then
	source "$d_PROGRAM"/includes/assume.shf
	f_ASSUME="$( fn_find_pwd )"

	b_ADD_INCLUDE=true
	if [[ -n "$f_ASSUME" ]]; then
		fn_assume_include "$@"
	fi

	if [[ "$b_ADD_INCLUDE" == true ]]; then
		"$v_PERL" "$d_PROGRAM"/"$f_PERL_SCRIPT" $v_PERL_ARGS "$@" --include "$f_ASSUME"
	else
		"$v_PERL" "$d_PROGRAM"/"$f_PERL_SCRIPT" $v_PERL_ARGS "$@"
	fi
elif [[ -z "$1" || "$1" == "--create" ]]; then
	source "$d_PROGRAM"/includes/create.shf
	fn_create
elif [[ -n "$1" ]]; then
	echo "Unrecognized argument \"$1\""
fi


