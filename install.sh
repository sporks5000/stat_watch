#! /bin/bash

export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

### An optional command line argument can be given to install this elsewhere
d_INST="/usr/local/stat_watch"
if [[ -n "$1" && "${1:0:1}" == "/" ]]; then
	### Make sure it's an absolute path
	d_INST="$1"
fi
if [[ "${d_INST: -1}" == "/" ]]; then
	### Make sure it does not end in a slash
	d_INST="${d_INST:0:${#d_INST}-1}"
fi
### Make sure that the parent directory exists
d_INST_R="$( echo "$d_INST" | rev | cut -d "/" -f2- | rev )"
if [[ ! -d "$d_INST_R" ]]; then
	echo "'$d_INST_R' does not exist. Please create it first"
	exit 1
fi

### Find out where we are
f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" || true )"
if [[ -z $f_PROGRAM ]]; then
	f_PROGRAM="${BASH_SOURCE[0]}"
fi
d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && pwd )"

### Other variables
v_OUT="/dev/null"
v_FAIL=false

### Test that all of the variables are populated
if [[ -z "$d_PROGRAM" || -z "$d_INST_R" || -z "$d_INST" || -z "$v_OUT" ]]; then
	echo "There appear to have been issues with setting variables correctly. Exiting."
	exit 1
fi

### If there's a zip file, remove it
if [[ -f "$d_PROGRAM"/../stat_watch.tar.gz ]]; then
	rm -f "$d_PROGRAM"/../stat_watch.tar.gz
fi

### Make sure that we're not already in the installation directory
if [[ "$d_INST" == "$d_PROGRAM" ]]; then
	echo "These files already appear to be in the installation location"
else
	### If there is a previous install...
	if [[ -d "$d_INST" ]]; then
		### Copy over existing settings and details
		if [[ -d "$d_INST"/.stat_watch ]]; then
			cp -a "$d_INST"/.stat_watch "$d_PROGRAM"/ 2> "$v_OUT" || v_FAIL=true
			if [[ "$v_FAIL" == true ]]; then
				echo "Failed to copy working directory from previous install"
				exit 1
			fi
		fi

		### Move the previous install out of the way
		if [[ -d "$d_INST"_old ]]; then
			rm -rf "$d_INST"_old
		fi
		mv -f "$d_INST" "$d_INST"_old 2> "$v_OUT" || v_FAIL=true
		if [[ "$v_FAIL" == true ]]; then
			echo "Failed to remove previous install"
			exit 1
		fi
	fi

	### Move the directory we're installing into place
	cp -a "$d_PROGRAM" "$d_INST_R" 2> "$v_OUT" || v_FAIL=true
	if [[ "$v_FAIL" == true ]]; then
		echo "Failed to move Stat Watch to '$d_INST'"
		if [[ -d "$d_INST"_old ]]; then
			mv -f "$d_INST"_old "$d_INST"
		fi
		exit 1
	fi
fi

### Get all of the appropriate permissions in place
chmod 700 "$d_INST"/stat_watch.pl "$d_INST"/stat_watch_wrap.sh "$d_INST"/scripts/fold_out.pl "$d_INST"/tests/test.sh 2> "$v_OUT" || v_FAIL=true
chown -R root:root "$d_INST" 2> "$v_OUT" || v_FAIL=true
if [[ "$v_FAIL" == true ]]; then
	echo "Failed ensure that all the files had the correct ownership and permissions"
	exit 1
fi

### Create a symlink
mkdir -p /root/bin
ln -sf "$d_INST"/stat_watch_wrap.sh /root/bin/stat_watch 2> "$v_OUT" || v_FAIL=true
if [[ "$v_FAIL" == true ]]; then
	echo "Failed create a symlink for '$d_INST/stat_watch_wrap.sh' at '/root/bin/stat_watch'"
	exit 1
fi

### Delete the things that need to be removed
rm -f "$d_INST"/install.sh 2> "$v_OUT"
rm -fv "$d_PROGRAM" "$d_INST"_old 2> "$v_OUT"

echo "Installed successfully"