#! /bin/bash

v_PROGRAMDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd | sed "s/\([^/]\)$/\1\//" )"

if [[ ! -f "$v_PROGRAMDIR"/stat_watch.pl ]]; then
	echo "Cannot find \"stat_watch.pl\". It should be located in the same directory as this file"
	exit
fi

if [[ -e /usr/local/cpanel/3rdparty/bin/perl ]]; then
	v_PERL_BIN="/usr/local/cpanel/3rdparty/bin/perl"
else
	v_PERL_BIN="/usr/bin/perl"
fi

if [[ "$1" == "--run" ]]; then
	f_JOB_FILE="$2"
	v_ACCOUNT="$( echo "$f_JOB_FILE" | rev | cut -d "/" -f2 | rev )"
	v_DIR="$( echo "$f_JOB_FILE" | rev | cut -d "/" -f2- | rev )"
	if [[ ! -f "$v_DIR"/"$v_ACCOUNT"_files.txt ]]; then
		"$v_PERL_BIN" "$v_PROGRAMDIR"/stat_watch.pl --record -i "$f_JOB_FILE" -o "$v_DIR"/"$v_ACCOUNT"_files.txt -v 2> /dev/null
		"$v_PERL_BIN" "$v_PROGRAMDIR"/stat_watch.pl --backup -i "$f_JOB_FILE" "$v_DIR"/"$v_ACCOUNT"_files.txt 2> /dev/null
	else
		"$v_PERL_BIN" "$v_PROGRAMDIR"/stat_watch.pl --record -i "$f_JOB_FILE" -o "$v_DIR"/"$v_ACCOUNT"_files2.txt 2> /dev/null
		"$v_PERL_BIN" "$v_PROGRAMDIR"/stat_watch.pl --diff -i "$f_JOB_FILE" "$v_DIR"/"$v_ACCOUNT"_files.txt "$v_DIR"/"$v_ACCOUNT"_files2.txt --backup -o "$v_DIR"/"$v_ACCOUNT"_changes_"$( date +%s )".txt --format text 2> /dev/null
		##### Send mail
		mv -f "$v_DIR"/"$v_ACCOUNT"_files2.txt "$v_DIR"/"$v_ACCOUNT"_files.txt
	fi
	exit
fi

read -ep "What is the name of the account that you're creating a stat_watch job for? " v_ACCOUNT
if [[ $( egrep "^""$v_ACCOUNT"":" -c /etc/passwd ) -lt 1 ]]; then
	echo "Account \"$v_ACCOUNT\" Does not exist"
	exit
else
	v_HOMEDIR="$( egrep "^""$v_ACCOUNT"":" /etc/passwd | cut -d ":" -f6 )"
fi

if [[ $( stat -c %n /*/stat_watch/ 2> /dev/null | wc -l ) -gt 0 ]]; then
	echo "There are currently stat_watch working directories in the following locations:"
	stat -c %n /*/stat_watch/ 2> /dev/null | sed "s/^/   /"
	echo
fi

read -ep "What partition do you want backups to be placed on? " v_PART
if [[ ! -d "$v_PART" ]]; then
	if [[ -d "/""$v_PART" ]]; then
		v_PART="/""$v_PART"
	else
		echo "\"$v_PART\" Is not a partition"
		exit
	fi
fi

if [[ -d "$v_HOMEDIR""/public_html" ]]; then
	read -ep "Monitor directory \"$v_HOMEDIR""/public_html\"? " v_YN
	if [[ $( echo "$v_YN" | egrep -c "^[yY]" ) -gt 0 ]]; then
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

mkdir -p "$v_PART"/stat_watch/"$v_ACCOUNT"/backup
touch $v_PART/stat_watch/$v_ACCOUNT/$v_ACCOUNT.log

cat << EOF > "$v_PART"/stat_watch/"$v_ACCOUNT"/"$v_ACCOUNT".job
I $v_MONITOR
BackupD $v_PART/stat_watch/$v_ACCOUNT/backup
BackupR \.(php(4|5|7)?|js|css|html|pl|sh|htaccess)$
BackupMD 4
BackupMC 7
Log $v_PART/stat_watch/$v_ACCOUNT/$v_ACCOUNT.log
EOF

echo
echo "A job file has been created at \""$v_PART"/stat_watch/"$v_ACCOUNT"/"$v_ACCOUNT".job\""
echo "Run \"$v_PROGRAMDIR/stat_watch.pl --help\" for further information on how it can be edited to suit your needs"
echo "Once you have that file organized as you need it, run the following command:"
echo
echo "$v_PROGRAMDIR"/stat_watch_wrap.sh --run "$v_PART"/stat_watch/"$v_ACCOUNT"/"$v_ACCOUNT".job
echo
echo "Then add the following line to root's crontab:"
echo
echo "* */2 * * * "$v_PROGRAMDIR"/stat_watch_wrap.sh --run "$v_PART"/stat_watch/"$v_ACCOUNT"/"$v_ACCOUNT".job > /dev/null 2>&1"
echo
