#! /bin/bash
### A wrapper script for stat_watch.pl
### Created by ACWilliams

v_VERSION="1.1.0";

f_PERL_SCRIPT="stat_watch.pl"
d_WORKING="stat_watch"
### Set a one in 10 chance of us pruning old backups
v_PRUNE_MAX=10
v_PRUNE_CHANCE=1
v_MAX_RUN=3600
v_LOG_MAX=10485760

### Find out where we are and make sure that stat_watch.pl is here too
v_PROGRAMDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
v_PROGRAMNAME="$( basename "${BASH_SOURCE[0]}" )"
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
if [[ ! -f "$v_PROGRAMDIR"/."$d_WORKING"/md5.pm ]]; then
	echo
	echo "\"$v_PROGRAMDIR/$f_PERL_SCRIPT\" might not function as expected without the file \"$v_PROGRAMDIR/.$d_WORKING/md5.pm\":"
	echo "https://raw.githubusercontent.com/sporks5000/stat_watch/master/.stat_watch/md5.pm"
	echo
	sleep 2
else
	v_MODULES=''
	if [[ $( "$v_PERL" -e "use Digest::MD5;" | head -n1 | egrep -c "^Can't locate" ) -gt 0 ]]; then
		v_MODULES="$v_MODULES Digest::MD5"
	fi
	if [[ $( "$v_PERL" -e "use Digest::MD5::File;" | head -n1 | egrep -c "^Can't locate" ) -gt 0 ]]; then
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

function fn_get_script {
### Given an identifier from the job file, rind the script and all command line arguments that follow
	local a_SCRIPT=()
	local v_SCRIPT_IDENT="$1"
	v_SCRIPT="$( grep -E "^\s*$v_SCRIPT_IDENT" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*$v_SCRIPT_IDENT[[:blank:]]*//;s/[[:blank:]]*$//" )"
	if [[ -n $v_SCRIPT ]]; then
		local word
		for word in $( echo $v_SCRIPT ); do
			a_SCRIPT[${#a_SCRIPT[@]}]="$word"
		done
		if [[ ${a_SCRIPT[0]:0:1} != "/" ]]; then
			unset v_SCRIPT
		elif [[ ! -n "${a_SCRIPT[0]}" || ! -f "${a_SCRIPT[0]}" || ! -x "${a_SCRIPT[0]}" ]]; then
			unset v_SCRIPT
		fi
	fi
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
cat << EOF | fold -s -w $(( $(tput cols) - 1 )) > /dev/stdout

$v_PROGRAMNAME is a wrapper script for $f_PERL_SCRIPT, designed with the goal of automating the most common processes and workflows anticipated for usage of $f_PERL_SCRIPT. Both of these scripts are part of the Stat Watch project


USAGE

./$v_PROGRAMNAME
    - Asks the user key questions in order to create a Stat Watch job to watch and backup key user files
    - By default, this will enable backup for files that end with the following: .php, .php4, .php5, .php7, .pl, .pm, .py, .js, .json, .css, .cgi .htm, .html, .htaccess, .htpasswd, .sh, .rb
    - What files are being checked and what files are being backed up can be modified by editing the .job file that this script creates

./$v_PROGRAMNAME --run [FILE]
    - Runs the necessary commands to complete a Stat Watch job, including checking the stats of files, determining th edifferences, and backing up files when necessary
    - FILE is the .job file created by $v_PROGRAMNAME
    - Adding the "--errors" flag after the file will prevent errors from $v_PROGRAMDIR/$f_PERL_SCRIPT from being routed to /dev/null

./$v_PROGRAMNAME --email-test [EMAIL ADDRESS]
    - Sends a test message to the email address specified so that the end recipient can see an example

./$v_PROGRAMNAME --help
./$v_PROGRAMNAME -h
    - Outputs this text


CONTROL STRINGS

The help output for "$v_PROGRAMDIR/$f_PERL_SCRIPT" explains a number of control strings that can be used in Stat Watch ignore / include files. $v_PROGRAMNAME checks for a few additional control strings that help regulate how it functions. Read the $f_PERL_SCRIPT help text for full details on how control strings work.
    - "Name" - This is used to designate the name of the job. Without this set, $v_PROGRAMNAME will not run
    - "Email" - This is used to designate an email adress (or multiple space separated email addresses) for results to be sent to 
    - "Expire" - When this is followed by a unix timestamp, the job will stop running after that timestamp is reached, and all associated files (except for the log file) will be deleted fifteen days later
    - "Max-run" - If a job is started only to find an earlier iteration of itself running, and that earlier iteration has been running for more than this number of seconds, that job will be killed
    - "Prune-max" - Pruning old backups will occur X out of every Y runs. "Prune-max" designates the "Y". Without this set, the default is 10.
    - "Prune-chance" - Pruning old backups will occur X out of every Y runs. "Prune-chance" designates the "X". Without this set, the default is 1.
    - "Email-no-changes" - If this control string is present, send emails even if there are no changes.
    - "Log-max" - A number following this control string will designate the maximum size (in bytes) of the log before it's trimmed. Without this set, the default is 10485760.
    - "Run-start" - At the start of the Stat Watch job, before any uses of $f_PERL_SCRIPT, attempt to run the script (with any given flags and arguments) that follows this control string
        - The full path to the script must be used
    - "Run-end" - At the end of the Stat Watch job, after all "--record" "--backup" or "--diff" uses of $f_PERL_SCRIPT, attempt to run the script (with any given flags and arguments) that follows this control string
        - The full path to the script must be used


JOB FILES

There are a number of files assiciated with each Stat Watch job. Here is an explanation of each of them.

./backup_[JOB NAME]
    - This directory contains the backups of files as specified by the .job file

./[JOB NAME]_changes_[EPOCH STAMP].txt
    - When changes are detected, this is a copy of file that's sent to the customer describing those changes

./[JOB NAME]_files.txt
    - This is the most recent Stat Watch report generated by "$v_PROGRAMDIR/$f_PERL_SCRIPT --record"

./[JOB NAME]_files2.txt
    - While the job is running, this file contians the most recent report, which is compared against ./[JOB NAME]_files.txt. At the end of the job, this file is moved to replace ./[JOB NAME]_files.txt

./[JOB NAME].job
    - This file defines how the job will function. It's the file that needs to be edited in order to make changes to the job.

./[JOB NAME].log
    - This file contains logs for everything that has occurred as part of the job. If the job expires and is removed as a result of the "Expire" control string, this is the only file that will be left afterward.

./[JOB NAME]_mesasage.txt
    - If this file exists, its contents will be added to the beginning of each email message sent.

./[JOB NAME]_run
    - This directory is in place to indicate that the Stat Watch job is currently running and to prevent two jobs from running concurrently

./[JOB NAME]_run/epoch
    - This file contains the timstamp of when the currently running job started

./[JOB NAME]_run/pid
    - This file contains the process id of the current running job

./[JOB NAME]_stamp
    - This file contains the last timestamp of when ./[JOB NAME].job was modified. If the timestamp here doesn't match the timestamp of that file, a check is run to see if we're checking new files or directories that have not been backed up yet


OTHER DETAILS

1) A list of jobs created by this script will be stored in the file "$v_PROGRAMDIR/.$d_WORKING/wrap_jobs_created".

2) For a better understanding of what functions are available under $f_PERL_SCRIPT, run "$v_PROGRAMDIR/$f_PERL_SCRIPT --help" for more information.


FEEDBACK

Report any errors, unexpected behaviors, comments, or feedback to acwilliams@liquidweb.com

EOF
#'#"# in #'#"
exit
elif [[ "$1" == "--version" ]]; then
cat << EOF | fold -s -w $(( $(tput cols) - 1 )) > /dev/stdout
Current Version: $v_VERSION

Version Notes:

1.1.0 (2018-08-17) -
    - Added the ability to turn off error supression
    - Added the ability to un helper-scripts before and after the main portions fo the Stat Watch job

1.0.1 (2018-08-10) -
    - Added log trimming to prevent the log from going out of control (like Dave Coulier)

1.0.0 (2018-08-07) -
    - Original Version

EOF
#'do
exit 0
elif [[ "$1" == "--run" ]]; then
### Here's the part for if we're running a job
	f_JOB_FILE="$2"
	if [[ ! -f "$f_JOB_FILE" ]]; then
		echo "No such file"
		exit
	fi
	v_ERROR_OUT="/dev/null"
	if [[ -n $3 && "$3" == "--errors" ]]; then
		v_ERROR_OUT="/dev/stderr"
	fi
	v_NAME="$( grep -E "^\s*Name" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Name[[:blank:]]*//;s/[[:blank:]]*$//" )"
	if [[ -z $v_NAME ]]; then
		echo "Cannot find name in Job file. Exiting"
		exit
	fi
	v_DIR="$( echo "$f_JOB_FILE" | rev | cut -d "/" -f2- | rev )"
	v_EXPIRE="$( grep -E "^\s*Expire" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Expire[[:blank:]]*//;s/[[:blank:]]*$//" )"
	### Create a directory to stand as an indicator that a job is running
	mkdir "$v_DIR"/"$v_NAME"_run 2> "$v_ERROR_OUT" || v_EXIT=true
	if [[ $v_EXIT == true ]]; then
		### This won't be 100% effective, but it should prevent most instances of this running twice at the same time
		sleep 0.$(( RANDOM % 10 ))
		v_PID="$( cat "$v_DIR"/"$v_NAME"_run/pid 2> "$v_ERROR_OUT" )"
		if [[ -n $v_PID && $( cat /proc/$v_PID/cmdline 2> "$v_ERROR_OUT" | grep -F -c "$v_PROGRAMDIR/$v_PROGRAMNAME" ) -gt 0 ]]; then
			v_EPOCH="$( cat "$v_DIR"/"$v_NAME"_run/epoch 2> "$v_ERROR_OUT" )"
			### check to see if the job has run for too long
			v_MAX_RUN2="$( grep -E "^\s*Max-run" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Max-run[[:blank:]]*//;s/[[:blank:]]*$//" )"
			if [[ -n $v_MAX_RUN2 && $( echo "$v_MAX_RUN" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
				v_MAX_RUN="$v_MAX_RUN2"
			fi
			### Are there reasons to kill the job?
			v_KILL=false
			if [[ -z $v_EPOCH ]]; then
				v_KILL=true
			elif [[ $( echo "$v_EPOCH" | grep -E -c "^[0-9]+$" ) -lt 1 ]]; then
				v_KILL=true
			elif [[ $(( $( date +%s ) - $v_EPOCH )) -gt $v_MAX_RUN ]]; then
				v_KILL=true
			fi
			### If so, let's kill it
			if [[ $v_KILL == true ]]; then
				kill -9 $v_PID
				if [[ -n $v_EPOCH || $( echo "$v_EPOCH" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
					echo "$( date +%Y-%m-%d" "%T" "%z ) - Job killed after running for $(( $( date +%s ) - $v_EPOCH )) seconds" >> "$v_DIR"/"$v_NAME".log
				fi
				rm -rf "$v_DIR"/"$v_NAME"_run
				echo "Previous job ran too long. Exiting"
				exit
			else
				echo "An existing iteration of this job is already running"
				exit
			fi
		fi
	fi
	echo "$$" > "$v_DIR"/"$v_NAME"_run/pid
	echo "$( date +%s )" > "$v_DIR"/"$v_NAME"_run/epoch
	if [[ -n $v_EXPIRE && $( echo "$v_EXPIRE" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
	### If the job was set to expire, see if we still need to run it
		if [[ $( date +%s ) -gt $v_EXPIRE ]]; then
			if [[ $( date --date="now - 15 days" +%s ) -gt $v_EXPIRE ]]; then
			### If we're 15 days past expiration, delete everything
				echo "$( date +%Y-%m-%d" "%T" "%z ) - Removing job \"$f_JOB_FILE\"" >> "$v_DIR"/"$v_NAME".log
				rm -f "$v_DIR"/"$v_NAME"_files.txt "$v_DIR"/"$v_NAME"_files2.txt "$v_DIR"/"$v_NAME"_changes_*.txt "$v_DIR"/"$v_NAME"_mesasage.txt "$v_DIR"/"$v_NAME"_stamp
				rm -rf "$v_DIR"/backup_"$v_NAME"
				rm -f "$f_JOB_FILE"
			fi
			rm -rf "$v_DIR"/"$v_NAME"_run
			exit
		fi
	fi
	fn_get_script "Run-start"; v_RUN_START="$v_SCRIPT"
	fn_get_script "Run-end"; v_RUN_END="$v_SCRIPT"
	if [[ ! -f "$v_DIR"/"$v_NAME"_files.txt ]]; then
	### If this is the first run, do an initial backup of files
		eval "$v_RUN_START"
		stat -c '%Y' "$f_JOB_FILE" > "$v_DIR"/"$v_NAME"_stamp
		nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --record -i "$f_JOB_FILE" -o "$v_DIR"/"$v_NAME"_files.txt -v 2> "$v_ERROR_OUT"
		nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --backup -i "$f_JOB_FILE" "$v_DIR"/"$v_NAME"_files.txt 2> "$v_ERROR_OUT"
		eval "$v_RUN_END"
	else
	### If this is a later run, diff the reports, and if there were changes, email them out
		eval "$v_RUN_START"
		nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --record -i "$f_JOB_FILE" -o "$v_DIR"/"$v_NAME"_files2.txt 2> "$v_ERROR_OUT"
		if [[ $( stat -c '%Y' "$f_JOB_FILE" ) -gt $( cat "$v_DIR"/"$v_NAME"_stamp 2> "$v_ERROR_OUT" ) ]]; then
			### If the job file has been updated, there's a chance that we need to back up additional files
			nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --backup -i "$f_JOB_FILE" "$v_DIR"/"$v_NAME"_files2.txt 2> "$v_ERROR_OUT"
			### ypdate the stat file so that we know not to do that next time
			stat -c '%Y' "$f_JOB_FILE" > "$v_DIR"/"$v_NAME"_stamp
		fi
		v_STAMP="$( date +%s )"
		nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --diff --no-check-retention -i "$f_JOB_FILE" "$v_DIR"/"$v_NAME"_files.txt "$v_DIR"/"$v_NAME"_files2.txt --backup -o "$v_DIR"/"$v_NAME"_changes_"$v_STAMP".txt --format text 2> "$v_ERROR_OUT"
		eval "$v_RUN_END"
		### this file should contain at least two lines
		if [[ $( wc -l "$v_DIR"/"$v_NAME"_files2.txt 2> "$v_ERROR_OUT" | cut -d " " -f1 ) -gt 1 ]]; then
			mv -f "$v_DIR"/"$v_NAME"_files2.txt "$v_DIR"/"$v_NAME"_files.txt
			if [[ $( wc -l "$v_DIR"/"$v_NAME"_changes_"$v_STAMP".txt 2> "$v_ERROR_OUT" | cut -d " " -f1 ) -lt 2 ]]; then
				v_NO_CHANGE="$( grep -E -c "^\s*Email-no-changes\s*$" "$f_JOB_FILE" )"
				if [[ $v_NO_CHANGE -gt 1 ]]; then
					v_EMAIL="$( grep -E "^\s*Email" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Email[[:blank:]]*//;s/[[:blank:]]*$//" )"
					if [[ -n $v_EMAIL ]]; then
						( 
							if [[ -f "$v_DIR"/"$v_NAME"_mesasage.txt ]]; then 
								cat "$v_DIR"/"$v_NAME"_mesasage.txt; 
								echo; 
							fi
							echo "No changes were detected."
							echo
							echo "This output was generated by \"$v_PROGRAMDIR/$f_PERL_SCRIPT\" and \"$v_PROGRAMDIR/$v_PROGRAMNAME\" from the job file at \"$f_JOB_FILE\'"
						) | mail -s "Stat Watch - No changed detected on $(hostname)" $v_EMAIL
					fi
				else
					rm -f "$v_DIR"/"$v_NAME"_changes_"$v_STAMP".txt
				fi
			else
			### If there were changes, check if we have an email address and then send a message to it
				v_EMAIL="$( grep -E "^\s*Email" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Email[[:blank:]]*//;s/[[:blank:]]*$//" )"
				if [[ -n $v_EMAIL ]]; then
					( 
						if [[ -f "$v_DIR"/"$v_NAME"_mesasage.txt ]]; then 
							cat "$v_DIR"/"$v_NAME"_mesasage.txt; 
							echo; 
						fi
						cat "$v_DIR"/"$v_NAME"_changes_"$v_STAMP".txt 
						echo
						echo "This output was generated by \"$v_PROGRAMDIR/$f_PERL_SCRIPT\" and \"$v_PROGRAMDIR/$v_PROGRAMNAME\" from the job file at \"$f_JOB_FILE\""
					) | mail -s "Stat Watch - File changes on $(hostname)" $v_EMAIL
				fi
			fi
		else
			rm -f "$v_DIR"/"$v_NAME"_files2.txt
		fi

		### Check to see if the user set the prune variables to soemthing different
		v_PRUNE_MAX2="$( grep -E "^\s*Prune-max" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Prune-max[[:blank:]]*//;s/[[:blank:]]*$//" )"
		if [[ -n $v_PRUNE_MAX2 && $( echo "$v_PRUNE_MAX2" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
			v_PRUNE_MAX="$v_PRUNE_MAX2"
		fi
		v_PRUNE_CHANCE2="$( grep -E "^\s*Prune-chance" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Prune-chance[[:blank:]]*//;s/[[:blank:]]*$//" )"
		if [[ -n $v_PRUNE_CHANCE2 && $( echo "$v_PRUNE_CHANCE2" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
			v_PRUNE_CHANCE="$v_PRUNE_CHANCE2"
		fi

		### Determine whether or not we're purning old backups
		if [[ $(( $v_PRUNE_CHANCE + RANDOM % $v_PRUNE_MAX )) -le $v_PRUNE_CHANCE ]]; then
			nice -15 "$v_PROGRAMDIR"/"$f_PERL_SCRIPT" --prune -i "$f_JOB_FILE" 2> "$v_ERROR_OUT"
		fi
	fi

	### Trim lines from the beginning of the log if necessary
	v_LOG_MAX2="$( grep -E "^\s*Log-max" "$f_JOB_FILE" | tail -n1 | sed "s/^[[:blank:]]*Log-max[[:blank:]]*//;s/[[:blank:]]*$//" )"
	if [[ -n $v_LOG_MAX2 && $( echo "$v_LOG_MAX2" | grep -E -c "^[0-9]+$" ) -gt 0 ]]; then
		v_LOG_MAX="$v_LOG_MAX2"
	fi
	if [[ $( stat -c %s "$v_DIR"/"$v_NAME".log ) -gt $v_LOG_MAX ]]; then
		printf "%s\n" "1,1000d" w | ed -s "$v_DIR"/"$v_NAME".log 2> "$v_ERROR_OUT"
	fi

	rm -rf "$v_DIR"/"$v_NAME"_run
	exit
elif [[ "$1" == "--email-test" ]]; then
	if [[ -z $2 ]]; then
		echo "Please provide an email address to test sending messages to"
		exit
	fi
	v_EMAIL="$2"
	(  
		echo "This is a test message to confirm that mesages from server $(hostname) are reaching the address \"$v_EMAIL\"."
		echo
		echo "If you were not expecting this message, please ignore it as it was likely sent in error."
	) | mail -s "Stat Watch - File changes on $(hostname)" $v_EMAIL
	echo "Test message sent to \"$v_EMAIL\""
	exit
elif [[ -n $1 ]]; then
	echo "Unrecognized argument \"$1\""
	exit
fi

### Prompt for basic details about the job that we're going to create
read -ep "What is the name of the account that you're creating a stat_watch job for? " v_ACCOUNT
if [[ $( grep -E "^""$v_ACCOUNT"":" -c /etc/passwd ) -lt 1 ]]; then
	echo "Account \"$v_ACCOUNT\" Does not exist"
	exit
else
	v_HOMEDIR="$( grep -E "^""$v_ACCOUNT"":" /etc/passwd | cut -d ":" -f6 )"
fi
if [[ -d "$v_HOMEDIR""/public_html" ]]; then
	read -ep "Monitor directory \"$v_HOMEDIR""/public_html\" (y/N)? " v_YN
	if [[ $( echo "$v_YN" | grep -E -c "^[yY]" ) -gt 0 ]]; then
		v_MONITOR="$v_HOMEDIR""/public_html"
	fi
fi
if [[ -z $v_MONITOR ]]; then
	read -ep "Name one directory we should monitor: " v_MONITOR
	if [[ ! -e $v_MONITOR ]]; then
		echo "\"$v_MONITOR\" is not a directory"
		exit
	fi
fi
read -ep "Is there a specific name you want to use for this job (leave blank for \"$v_ACCOUNT\")? " v_NAME
if [[ -z $v_NAME ]]; then
	v_NAME="$v_ACCOUNT"
fi

### And figure out where we're going to store this job
if [[ $( stat -c %n /*/"$d_WORKING"/ 2> /dev/null | wc -l ) -gt 0 ]]; then
	echo "There are currently stat_watch working directories in the following root-level directory:"
	stat -c %n /*/"$d_WORKING"/ 2> /dev/null | sed "s/^/   /;s/\/$d_WORKING\/$//"
	echo
fi
read -ep "What root-level directory do you want backups to be placed on? " v_PART
if [[ ! -d "$v_PART" ]]; then
	if [[ -d "/""$v_PART" ]]; then
		v_PART="/""$v_PART"
	else
		echo "\"$v_PART\" Is not a root-level directory"
		exit
	fi
fi
v_DIR="$v_PART"/"$d_WORKING"/"$v_ACCOUNT"
if [[ -f "$v_DIR"/"$v_NAME".job ]]; then
	echo "There already appears to be a stat_watch job at \""$v_DIR"/"$v_NAME".job\". You can delete or modify that."
	exit
fi

### Prompt if the job should stop running after 45 days
read -ep "Do you want this job to stop running after 45 days, and for all backed up files to be removed after 60 days (Y/n)? " v_YN
if [[ $( echo "$v_YN" | grep -E -c "^[nN]" ) -eq 0 ]]; then
	v_EXPIRE=true
fi

### Prompt for an email address to send reports to
read -ep "What email address should reports be sent to (leave blank for none)? " v_EMAIL
if [[ -n $v_EMAIL ]]; then
	echo -e "\e[91m"
	echo "If $v_EMAIL is a customer-facing address, MAKE SURE that appropriate expectations have been set for how these emails will be followed up on."
	echo "Here is an example of setting such expectations: https://raw.githubusercontent.com/sporks5000/stat_watch/master/texts/expectations.txt"
	echo
	echo "Note: If you create a file at \"$v_DIR/$v_NAME""_message.txt, the contents of that file will be sent at the top of each email message. It might be wise to set expectations there as well"
	echo -e "\e[0m"
	### Pause here, because I SUPER want people to read this
	sleep 10
fi

### Create the relevant files
mkdir -p "$v_DIR"/backup_"$v_NAME"
touch $v_DIR/$v_NAME.log
f_JOB_FILE="$v_DIR/$v_NAME".job
cat << EOF > "$f_JOB_FILE"
### This file created by $v_PROGRAMNAME
I $v_MONITOR
BackupD $v_DIR/backup_$v_NAME
### back up the following extensions: .php, .php4, .php5, .php7, .pl, .pm, .py, .js, .json, .css, .cgi .htm, .html, .htaccess, .htpasswd, .sh, .rb
BackupR \.(p(hp(4|5|7)?|[lym])|js(on)?|c(ss|gi)|ht(ml?|access|passwd)|sh|rb)$
BackupMD 7
BackupMC 4
Log $v_DIR/$v_NAME.log

### These lines specific to the functionality of $v_PROGRAMNAME
Name $v_NAME
EOF
if [[ -n $v_EMAIL ]]; then
	echo "Email $v_EMAIL" >> "$f_JOB_FILE"
fi
if [[ $v_EXPIRE == true ]]; then
	echo "Expire $( date --date="now + 45 days" +%s )" >> "$f_JOB_FILE"
fi

### Log that the job was created by this script
echo "$( date +%Y-%m-%d" "%T" "%z ) - Job \"$f_JOB_FILE\" created by $v_PROGRAMNAME" >> "$v_DIR"/"$v_NAME".log

### Create a working directory and a file to document jobs created
mkdir -p $v_PROGRAMDIR/."$d_WORKING"
f_TEMP=$( mktemp )
grep -E -v "^$f_JOB_FILE - Created " "$v_PROGRAMDIR"/."$d_WORKING"/wrap_jobs_created > "$f_TEMP" 2> /dev/null
echo "$f_JOB_FILE - Created $( date +%Y-%m-%d" "%T" "%z )" >> "$f_TEMP"
mv -f "$f_TEMP" "$v_PROGRAMDIR"/."$d_WORKING"/wrap_jobs_created

### Output text telling the user what next steps they need to take
echo
echo -e "A job file has been created at \"\e[92m$f_JOB_FILE\e[0m\""
echo "Run \"$v_PROGRAMDIR/$f_PERL_SCRIPT --help\" for further information on how it can be edited to suit your needs"
echo "Once you have that file organized as you need it, run the following command:"
echo
echo "$v_PROGRAMDIR/$v_PROGRAMNAME --run \"$f_JOB_FILE\""
echo
echo "Then add the following line to root's crontab (adjusting times if necessary):"
echo
### set a random minute from 1 to 59 for the cron job to run
echo "$(( 1 + RANDOM % 58 )) */2 * * * $v_PROGRAMDIR/$v_PROGRAMNAME --run "$f_JOB_FILE" > /dev/null 2>&1"
echo
