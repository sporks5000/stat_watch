#! /bin/bash
### Given a directory, get stats for all files and subdirectories
### Useful for seeing what has changed since the last time this was run
### Created by ACWilliams

### USAGE
###
### ./get_stats.sh --record [DIRECTORY] ([DIRECTORY 2] ...)
### outputs stat data for all of the files under the directory specified (you probably want to redirect this output to a file)
### The "-v" or "--verbose" flag can be used to have the directories output to STDERR
### The "-i" or "--ignore" or "--include" flag can be used to specify an ignore/include file
### This is the default functionality. Technically the "--record" flag is not necessary
###
### ./get_stats.sh --diff [FILE 1] [FILE 2] ([IGNORE FILE])
### Show a diff of the two files

### REGARDING THE IGNORE/INCLUDE FILE
###
### Each line of the ignore file should include a full path to the file or directory being ignored (beginning with "/").
### Any line containing a directory will result in that directory and all subdirectories being ignored
### Lines beginning with an asterisk ("*") followed by the start of a full path will be interpreted as any file that begins with that full path
### The lines will be interpreted with egrep. Lines beginning with a capital "R" will be taken as is; all other lines will have appropriate escaping added
### Any line beginning with a capital "Z" indicates that the file or directory itself should not be logged, but (assuming it's a directory) any contents should
### The "R" "*" and "Z" control characters can be used together in any combination
### Any line beginning with a capital "I" followed by the full path will be included in the list of directories. Other control characters cannot be used with "I"
### Includes will have no impact on "--diff" functionality
### Empty lines and any lines that do not begin with a slash, or one of the control characters mentioned above followed by a slash will be ignored
###
### If an ignore file was used for --record, there's no need to use it for --diff
### If a directory is included or given at the command line that would otherwise be ignored due to entries in the file, it will be checked

b_OUTPUT=false

function fn_get_stats {
	if [[ -d "$1" ]]; then
		### descend into the requested directory
		cd "$1"
		if [[ $b_OUTPUT != false ]]; then
			echo "Directory: $( pwd )" > /dev/stderr
		fi
		for i in $( ls -1A ); do
		### For each of the files, grab its stats
			if [[ -e "$i" ]]; then
				v_LINE="$( stat -c '‘'%n"’ -- "%A" -- "%u" -- "%g" -- "%s" -- "%y" -- "%z "$( pwd )""/""$i" )"
				if [[ -z $v_IGNORE || $( echo "$v_LINE" | egrep -vc "$v_IGNORE" ) -eq 1 ]]; then
					if [[ -z $v_NO_PRINT || $( echo "$v_LINE" | egrep -vc "$v_NO_PRINT" ) -eq 1 ]]; then
						echo $v_LINE
					fi
				fi
			fi
		done
		for i in $( ls -1A ); do
		### For each of the diles that is a directory, descend into that directory, and do this again
			if [[ ! -L "$i" && -d "$i" ]]; then
				if [[ -z $v_IGNORE || $( echo "$( stat -c '‘'%n"’ -- "%a "$( pwd )""/""$i" )" | egrep -vc "$v_IGNORE" ) -eq 1 ]]; then
					fn_get_stats "$( pwd )""/""$i"
					### And then come back out of that directory
					cd ..
				elif [[ $b_OUTPUT != false ]]; then
					echo "IGNORED: ""$( pwd )""/""$i" > /dev/stderr
				fi
			fi
		done
	elif [[ -f "$1" ]]; then
		v_LINE="$( stat -c '‘'%n"’ -- "%A" -- "%u" -- "%g" -- "%s" -- "%y" -- "%z "$1" )"
		if [[ -z $v_NO_PRINT || $( echo "$v_LINE" | egrep -vc "$v_NO_PRINT" ) -eq 1 ]]; then
			echo $v_LINE
		fi
	fi
}

function fn_get_ignore {
	if [[ -n "$1" ]]; then
		f_IGNORE="$1"
	fi
	if [[ -n "$f_IGNORE" && -f "$f_IGNORE" ]]; then
		### Lines that we want to escape regex characters for
		v_IGNORE1="$( egrep "^\s*/" "$f_IGNORE" | sed -r "s/^\s*//;s/\/$//;s/\s*$//;s/\/\/+/\//g" | sed 's/?/\\?/g; s/+/\\+/g; s/{/\\{/g; s/|/\\|/g; s/(/\\(/g; s/)/\\)/g; s/\./\\./g; s/\*/\\*/g; s/\$/\\$/g; s/\^/\\^/g; s/\[/\\[/g; s/\\/\\\\/g' | fn_check_dir | tr "\n" "|" | sed "s/|$//" )"
		v_IGNORE2="$( egrep "^\s*\*\s*/" "$f_IGNORE" | sed -r "s/^[\t \*]+//;s/\/$//;s/\s*$//" | sed 's/?/\\?/g; s/+/\\+/g; s/{/\\{/g; s/|/\\|/g; s/(/\\(/g; s/)/\\)/g; s/\./\\./g; s/\*/\\*/g; s/\$/\\$/g; s/\^/\\^/g; s/\[/\\[/g; s/\\/\\\\/g' | fn_check_dir | tr "\n" "|" | sed "s/|$//" )"

		### Lines that can be interpreted as regex
		v_IGNORE3="$( egrep "^\s*R\s*/" "$f_IGNORE" | sed -r "s/^[\t R]+//;s/\/$//;s/\s*$//;s/\/\/+/\//g" | fn_check_dir | tr "\n" "|" | sed "s/|$//" )"
		v_IGNORE4="$( egrep "^(\s*\*\s*R\s*|\s*R\s*\*\s*)/" "$f_IGNORE" | sed -r "s/^[\t R\*]+//;s/\/$//;s/\s*$//" | fn_check_dir | tr "\n" "|" | sed "s/|$//" )"

		### Now we put them all together
		if [[ -n $v_IGNORE1 || -n $v_IGNORE2 || -n $v_IGNORE3 || -n $v_IGNORE4 ]]; then
			v_IGNORE="^‘("
			if [[ -n $v_IGNORE1 || -n $v_IGNORE3 ]]; then
				if [[ -n $v_IGNORE1 && -n $v_IGNORE3 ]]; then
					v_IGNORE="$v_IGNORE""($v_IGNORE1|$v_IGNORE3)"
				else
					v_IGNORE="$v_IGNORE""($v_IGNORE1""$v_IGNORE3)"
				fi
				v_IGNORE="$v_IGNORE""(’ -- |/)"
				if [[ -n $v_IGNORE2 || -n $v_IGNORE4 ]]; then
					v_IGNORE="$v_IGNORE""|"
				fi
			fi
			if [[ -n $v_IGNORE2 && -n $v_IGNORE4 ]]; then
				v_IGNORE="$v_IGNORE""$v_IGNORE2|$v_IGNORE4"
			else
				v_IGNORE="$v_IGNORE""$v_IGNORE2""$v_IGNORE4"
			fi
			v_IGNORE="$v_IGNORE"")"
		fi

		### Process "Z" entries
		v_NO_PRINT1="$( egrep "^\s*Z\s*/" "$f_IGNORE" | sed -r "s/^[\t Z]+//;s/\/$//;s/\s*$//;s/\/\/+/\//g" | sed 's/?/\\?/g; s/+/\\+/g; s/{/\\{/g; s/|/\\|/g; s/(/\\(/g; s/)/\\)/g; s/\./\\./g; s/\*/\\*/g; s/\$/\\$/g; s/\^/\\^/g; s/\[/\\[/g; s/\\/\\\\/g' | tr "\n" "|" | sed "s/|$//" )"
		v_NO_PRINT2="$( egrep "^(\s*\*\s*Z\s*|\s*Z\s*\*\s*)/" "$f_IGNORE" | sed -r "s/^[\t Z\*]+//;s/\/$//;s/\s*$//" | sed 's/?/\\?/g; s/+/\\+/g; s/{/\\{/g; s/|/\\|/g; s/(/\\(/g; s/)/\\)/g; s/\./\\./g; s/\*/\\*/g; s/\$/\\$/g; s/\^/\\^/g; s/\[/\\[/g; s/\\/\\\\/g' | tr "\n" "|" | sed "s/|$//" )"

		### Lines that can be interpreted as regex
		v_NO_PRINT3="$( egrep "^(\s*R\s*Z\s*|\s*Z\s*R\s*)/" "$f_IGNORE" | sed -r "s/^[\t RZ]+//;s/\/$//;s/\s*$//;s/\/\/+/\//g" | tr "\n" "|" | sed "s/|$//" )"
		v_NO_PRINT4="$( egrep "^(\s*R\s*Z\s*\*\s*|\s*Z\s*R\s*\*\s*|\s*R\s*\*\s*Z\s*|\s*Z\s*\*\s*R\s*|\s*\*\s*Z\s*R\s*|\s*\*\s*R\s*Z\s*)/" "$f_IGNORE" | sed -r "s/^[\t RZ\*]+//;s/\/$//;s/\s*$//" | tr "\n" "|" | sed "s/|$//" )"

		if [[ -n $v_NO_PRINT1 || -n $v_NO_PRINT2 || -n $v_NO_PRINT3 || -n $v_NO_PRINT4 ]]; then
			v_NO_PRINT="^‘("
			if [[ -n $v_NO_PRINT1 || -n $v_NO_PRINT3 ]]; then
				if [[ -n $v_NO_PRINT1 && -n $v_NO_PRINT3 ]]; then
					v_NO_PRINT="$v_NO_PRINT""($v_NO_PRINT1|$v_NO_PRINT3)"
				else
					v_NO_PRINT="$v_NO_PRINT""($v_NO_PRINT1""$v_NO_PRINT3)"
				fi
				v_NO_PRINT="$v_NO_PRINT""’ -- "
				if [[ -n $v_NO_PRINT2 || -n $v_NO_PRINT4 ]]; then
					v_NO_PRINT="$v_NO_PRINT""|"
				fi
			fi
			if [[ -n $v_NO_PRINT2 && -n $v_NO_PRINT4 ]]; then
				v_NO_PRINT="$v_NO_PRINT""$v_NO_PRINT2|$v_NO_PRINT4"
			else
				v_NO_PRINT="$v_NO_PRINT""$v_NO_PRINT2""$v_NO_PRINT4"
			fi
			v_NO_PRINT="$v_NO_PRINT"")"
		fi
	elif [[ -z "$f_IGNORE" || ! -f "$f_IGNORE"  ]]; then
		unset v_IGNORE v_NO_PRINT
	fi
}

function fn_get_include {
	if [[ -n "$1" ]]; then
		f_IGNORE="$1"
	fi
	if [[ -n "$f_IGNORE" && -f "$f_IGNORE" ]]; then
		for v_INCLUDE in $( egrep "^\s*I\s*/" "$f_IGNORE" | sed -r "s/^\s*I\s*//;s/\/$//;s/\s*$//;s/\/\/+/\//g" ); do
			if [[ -d "$v_INCLUDE" || -f "$v_INCLUDE" ]]; then
			### add them to the list of directories
				a_DIRS[$c_DIRS]="$v_INCLUDE"
				c_DIRS=$(( c_DIRS + 1 ))
			fi
		done
	fi
}

function fn_ignore_dir_timestamps {
### Timestamps of directories can change for a lot of reasons. It makes sense to capture them, but when doing diffs, let's ignore them.
	while read v_LINE; do
		if [[ $( echo "$v_LINE" | egrep -c "’ -- d" ) -gt 0 ]]; then
			echo "$v_LINE" | rev | cut -d " " -f9- | rev
		else
			echo "$v_LINE"
		fi
	done
}

function fn_check_dir {
### Check each line from the ignore file. If it would negate the directory given at the command line, don't output it
	while read v_LINE; do
		if [[ $( echo "$v_CUR_DIR" | egrep -c "^$v_LINE" ) -eq 0 ]]; then
			echo "$v_LINE"
		fi
	done
}

#=====================#
#== Parse Arguments ==#
#=====================#

if [[ "$1" == "--record" || "${1:0:2}" != "--" ]]; then
### output the stats for all files
	a_CL_ARGUMENTS=( "$@" )
	c_DIRS=0
	v_OLD_IFS=$IFS
	for (( c=0; c<=$(( ${#a_CL_ARGUMENTS[@]} - 1 )); c++ )); do
	### Go through all of the command line arguments
		v_ARGUMENT="${a_CL_ARGUMENTS[$c]}"
		if [[ "$v_ARGUMENT" == "-v" || "$1" == "--verbose" ]]; then
		### Toggle verbose mode
			if [[ $b_OUTPUT == false ]]; then				
				b_OUTPUT=true
			else
				b_OUTPUT=false
			fi
		elif [[ "$v_ARGUMENT" == "-i" || "$v_ARGUMENT" == "--ignore" || "$v_ARGUMENT" == "--include" ]]; then
		### Capture the ignore file
			c=$(( $c + 1 ))
			f_IGNORE="${a_CL_ARGUMENTS[$c]}"
			fn_get_include "${a_CL_ARGUMENTS[$c]}"
		elif [[ -d "$v_ARGUMENT" || -f "$v_ARGUMENT" ]]; then
		### Anything else should be directories that we're investigating
			a_DIRS[$c_DIRS]="$v_ARGUMENT"
			c_DIRS=$(( c_DIRS + 1 ))
		fi
	done
	if [[ $c_DIRS -eq 0 ]]; then
		echo "No directories selected"
		exit
	fi
	IFS=$'\n'
	a_DIRS2=($(sort <<<"${a_DIRS[*]}"))
	for (( c=0; c<=$(( ${#a_DIRS2[@]} - 1 )); c++ )); do
	### go through all of the directories
		v_CUR_DIR="${a_DIRS2[$c]}"
		fn_get_ignore "$f_IGNORE"
		fn_get_stats "$v_CUR_DIR"
	done
	IFS=$v_OLD_IFS
elif [[ "$1" == "--diff" ]]; then
### display diffs for the files we're presented with
	v_FILE1="$2"
	v_FILE2="$3"
	if [[ -n "$4" && -f "$4" ]]; then
	### If we're given an ignore file, let's ignore the things in it
		fn_get_ignore "$4"
		diff <( egrep -v "$v_IGNORE|$v_NO_PRINT" "$v_FILE1" | fn_ignore_dir_timestamps ) <( egrep -v "$v_IGNORE|$v_NO_PRINT" "$v_FILE2" | fn_ignore_dir_timestamps )
	else
		diff <( cat "$v_FILE1" | fn_ignore_dir_timestamps ) <( cat "$v_FILE2" | fn_ignore_dir_timestamps )
	fi
else
	echo "Use \"--record\" or \"--diff\""
fi

