#! /bin/bash
### A wrapper script for stat_watch.pl
### Created by ACWilliams

f_PERL_SCRIPT="stat_watch.pl"
d_WORKING="stat_watch"

export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

### Find out where we are and make sure that stat_watch.pl is here too
f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" )"
if [[ -z $f_PROGRAM ]]; then
	f_PROGRAM="${BASH_SOURCE[0]}"
fi
d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && pwd )"
f_PROGRAM="$( basename "$f_PROGRAM" )"
f_JOBS="$d_PROGRAM"/."$d_WORKING"/wrap_jobs_created

v_PERL="/usr/bin/perl"
v_CPAN="/usr/bin/cpan"
if [[ ! -f "$d_PROGRAM"/"$f_PERL_SCRIPT" ]]; then
	echo "Cannot find \"$f_PERL_SCRIPT\". It should be located in the same directory as this file"
	exit
elif [[ -f /usr/local/cpanel/3rdparty/bin/perl ]]; then
	if  [[ $( head -n1 "$d_PROGRAM"/"$f_PERL_SCRIPT" | cut -d " " -f2 ) == "/usr/bin/perl" ]]; then
		### If cPanel's perl is present, change stat_watch.pl to use that
		sed -i '1 s@^.*$@#! /usr/local/cpanel/3rdparty/bin/perl@' "$d_PROGRAM"/"$f_PERL_SCRIPT"
	fi
	### If we're making this change, we need to modify what versions of perl and cpan we're referencing
	v_PERL="/usr/local/cpanel/3rdparty/bin/perl"
	v_CPAN="$( \ls -1 /usr/local/cpanel/3rdparty/perl/*/bin/cpan | tail -n1 )"
fi

### Test to ensure that the necessary perl modules are present
if [[ ! -f "$d_PROGRAM"/."$d_WORKING"/perl_modules ]]; then
	v_MODULES=''
	if [[ $( "$v_PERL" -e "use Digest::MD5;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5"
	fi
	if [[ $( "$v_PERL" -e "use Digest::MD5::File;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5::File"
	fi
	if [[ $( "$v_PERL" -e "use Cwd;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Cwd"
	fi
	if [[ $( "$v_PERL" -e "use POSIX;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES POSIX"
	fi
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
		"$d_PROGRAM"/"$f_PERL_SCRIPT" "$@" --include "$f_ASSUME"
	else
		"$d_PROGRAM"/"$f_PERL_SCRIPT" "$@"
	fi
elif [[ -z "$1" || "$1" == "--create" ]]; then
	source "$d_PROGRAM"/includes/create.shf
	fn_create
elif [[ -n "$1" ]]; then
	echo "Unrecognized argument \"$1\""
fi


