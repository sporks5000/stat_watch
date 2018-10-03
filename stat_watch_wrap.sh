#! /bin/bash
### A wrapper script for stat_watch.pl
### Created by ACWilliams

v_VERSION="1.1.2";

f_PERL_SCRIPT="stat_watch.pl"
d_WORKING="stat_watch"
### Set a one in 10 chance of us pruning old backups
v_PRUNE_MAX=10
v_PRUNE_CHANCE=1
v_MAX_RUN=3600
v_LOG_MAX=10485760
v_EMAIL_RETAIN=20

export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

### Find out where we are and make sure that stat_watch.pl is here too
v_PROGRAMNAME="$( readlink "${BASH_SOURCE[0]}" )"
if [[ -z $v_PROGRAMNAME ]]; then
	v_PROGRAMNAME="${BASH_SOURCE[0]}"
fi
v_PROGRAMDIR="$( cd -P "$( dirname "$v_PROGRAMNAME" )" && pwd )"
v_PROGRAMNAME="$( basename "$v_PROGRAMNAME" )"
f_JOBS="$v_PROGRAMDIR"/."$d_WORKING"/wrap_jobs_created

v_PERL="/usr/bin/perl"
v_CPAN="/usr/bin/cpan"
if [[ ! -f "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" ]]; then
	echo "Cannot find \"$f_PERL_SCRIPT\". It should be located in the same directory as this file"
	exit
elif [[ -f /usr/local/cpanel/3rdparty/bin/perl ]]; then
	if  [[ $( head -n1 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" | cut -d " " -f2 ) == "/usr/bin/perl" ]]; then
		### If cPanel's perl is present, change stat_watch.pl to use that
		sed -i '1 s@^.*$@#! /usr/local/cpanel/3rdparty/bin/perl@' "$v_PROGRAMDIR"/"$f_PERL_SCRIPT"
	fi
	### If we're making this change, we need to modify what versions of perl and cpan we're referencing
	v_PERL="/usr/local/cpanel/3rdparty/bin/perl"
	v_CPAN="$( \ls -1 /usr/local/cpanel/3rdparty/perl/*/bin/cpan | tail -n1 )"
fi

### Check if the md5 module is present
if [[ ! -f "$v_PROGRAMDIR"/scripts/md5.pm ]]; then
	echo
	echo "\"$v_PROGRAMDIR/$f_PERL_SCRIPT\" might not function as expected without the file \"$v_PROGRAMDIR/scripts/md5.pm\":"
	echo "https://raw.githubusercontent.com/sporks5000/stat_watch/master/scripts/md5.pm"
	echo
	sleep 2
else
	v_MODULES=''
	if [[ $( "$v_PERL" -e "use Digest::MD5;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5"
	fi
	if [[ $( "$v_PERL" -e "use Digest::MD5::File;" 2>&1 | head -n1 | grep -E -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5::File"
	fi
	if [[ -n $v_MODULES ]]; then
		echo
		echo "Attempting to install the necessary perl modules"
		echo
		sleep 2
		"$v_CPAN" -i $v_MODULES
		if [[ $? -ne 0 ]]; then
			echo "Failed to install perl modules" > /dev/stderr
			exit
		fi
		echo
	fi
fi

### If any of the arguments are asking for help, output help and exit
a_CL_ARGUMENTS=( "$@" )
for (( c=0; c<=$(( ${#a_CL_ARGUMENTS[@]} - 1 )); c++ )); do
	v_ARG="${a_CL_ARGUMENTS[$c]}"
	if [[ "$v_ARG" == "-h" || "$v_ARG" == "--help" ]]; then
		if [[ "${a_CL_ARGUMENTS[$c + 1]}" == "use-cases" ]]; then
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_usage.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "flags" ]]; then
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_flags.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "job" ]]; then
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_job_file.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "backups" ]]; then
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_backups.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		elif [[ "${a_CL_ARGUMENTS[$c + 1]}" == "job-files" ]]; then
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_job_files.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		else
			"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/help_header.txt "$v_PROGRAMDIR"/texts/help_basic.txt "$v_PROGRAMDIR"/texts/help_feedback.txt
		fi
		exit
	elif [[ "$v_ARG" == "--version" ]]; then
		"$v_PROGRAMDIR"/scripts/fold_out.pl "$v_PROGRAMDIR"/texts/version.txt
		exit
	fi
done

if [[ "$1" == "--run" ]]; then
### Here's the part for if we're running a job
	source "$v_PROGRAMDIR"/includes/run.shf
	shift
	fn_run "$@"
elif [[ "$1" == "--email-test" ]]; then
	if [[ -z "$2" ]]; then
		echo "Please provide an email address to test sending messages to"
		exit
	fi
	v_EMAIL="$2"
	(  
		echo "This is a test message to confirm that mesages from server $(hostname) are reaching the address \"$v_EMAIL\"."
		echo
		echo "If you were not expecting this message, please ignore it as it was likely sent in error."
		if [[ -n "$3" ]]; then 
			echo
			echo "$3" 
		fi
	) | mail -s "Stat Watch - File changes on $(hostname)" $v_EMAIL
	echo "Test message sent to \"$v_EMAIL\""
	exit
elif [[ "$1" == "--record" || "$1" == "--links" || "$1" == "--new-lines" || "$1" == "--diff" || "$1" == "--" || "$1" == "--backup" || "$1" == "--list" || "$1" == "--prune" || "$1" == "--md5-test" || "$1" == "--backup-file" || ( -n "$1" && "${1:0:2}" != "--" ) ]]; then
	"$v_PROGRAMDIR"/"$f_PERL_SCRIPT" "$@"
elif [[ -z "$1" || "$1" == "--create" ]]; then
	source "$v_PROGRAMDIR"/includes/create.shf
	fn_create
elif [[ -n "$1" ]]; then
	echo "Unrecognized argument \"$1\""
	exit
fi


