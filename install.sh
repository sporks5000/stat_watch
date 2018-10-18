#! /bin/bash

export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

### Initial variables
v_OUT="/dev/null"
v_FAIL=false

### Find out where we are
f_PROGRAM="$( readlink "${BASH_SOURCE[0]}" || true )"
if [[ -z $f_PROGRAM ]]; then
	f_PROGRAM="${BASH_SOURCE[0]}"
fi
d_PROGRAM="$( cd -P "$( dirname "$f_PROGRAM" )" && pwd )"
d_WORKING="$d_PROGRAM"/.stat_watch

### An optional command line argument can be given to install this elsewhere
d_INST="/usr/local/stat_watch"
if [[ -n "$1" && "${1:0:1}" == "/" ]]; then
	### Make sure it's an absolute path
	d_INST="$1"
elif [[ -n "$1" ]]; then
	echo "Must provide a full path to the installation directory"
	exit 1
fi
if [[ "${d_INST: -1}" == "/" ]]; then
	### Make sure it does not end in a slash
	d_INST="${d_INST:0:${#d_INST}-1}"
fi

### Test that all of the variables are populated
if [[ -z "$d_PROGRAM" || -z "$d_INST" || -z "$v_OUT" ]]; then
	echo "There appear to have been issues with setting variables correctly. Exiting."
	exit 1
fi

### Pull in utility functions
source "$d_PROGRAM"/includes/util.shf

### Make sure that the parent directory exists
fn_file_path "$d_INST"; d_INST_R="$s_DIR"
if [[ ! -d "$d_INST_R" ]]; then
	echo "Directory '$d_INST_R' does not exist. Please create it first"
	exit 1
fi

### If there's a zip file or git information, remove it
if [[ -f "$d_PROGRAM"/../stat_watch.tar.gz ]]; then
	rm -f "$d_PROGRAM"/../stat_watch.tar.gz
fi
if [[ -d "$d_PROGRAM"/.git ]]; then
	rm -rf "$d_PROGRAM"/.git
fi

### Make sure that we're not already in the installation directory
if [[ "$d_INST" == "$d_PROGRAM" ]]; then
	echo "These files already appear to be in the installation location"
else
	### If there is a previous install...
	if [[ -d "$d_INST" ]]; then
		### Copy over existing settings and details
		if [[ -d "$d_INST"/.stat_watch ]]; then
			cp -af "$d_INST"/.stat_watch "$d_PROGRAM"/ 2> "$v_OUT" || v_FAIL=true
			if [[ "$v_FAIL" == true ]]; then
				echo "Failed to copy working directory from previous install"
				exit 1
			fi
			if [[ -f "$d_PROGRAM"/.stat_watch/perl_modules ]]; then
				rm -f "$d_PROGRAM"/.stat_watch/perl_modules
			fi
		fi

		### If there's a configuration file, port over those details
		if [[ -f "$d_INST"/stat_watch.conf ]]; then
			source "$d_PROGRAM"/includes/conf_version.shf
			v_CONF_VERSION_NEW="$v_CONF_VERSION"
			if [[ -f "$d_INST"/includes/conf_version.shf ]]; then
				source "$d_INST"/includes/conf_version.shf
				### We only need to overwrite the configuration if the versions don't match, otherwise the old one is fine
				if [[ "$v_CONF_VERSION" != "$v_CONF_VERSION_NEW" ]]; then
					source "$d_PROGRAM"/includes/variables.shf
					fn_read_conf "$d_INST"/stat_watch.conf
					fn_write_conf2
					fn_make_conf
				else
					cp -af "$d_INST"/stat_watch.conf "$d_PROGRAM"/stat_watch.conf 2> "$v_OUT"
				fi
			fi
		else
		### If there isn't a configuration file, MAKE one
			source "$d_PROGRAM"/includes/variables.shf
			fn_conf_defaults
			fn_write_conf2
			fn_make_conf
		fi

		### Move the previous install out of the way
		if [[ -d "$d_INST"_old ]]; then
			rm -rf "$d_INST"_old 2> "$v_OUT"
		fi
		mv -f "$d_INST" "$d_INST"_old 2> "$v_OUT" || v_FAIL=true
		if [[ "$v_FAIL" == true ]]; then
			echo "Failed to remove previous install"
			exit 1
		fi
	fi

	### Move the directory we're installing into place
	cp -af "$d_PROGRAM" "$d_INST_R" 2> "$v_OUT" || v_FAIL=true
	if [[ "$v_FAIL" == true ]]; then
		echo "Failed to move Stat Watch to '$d_INST'"
		if [[ -d "$d_INST"_old ]]; then
			mv -f "$d_INST"_old "$d_INST"
		fi
		exit 1
	fi
fi

### Set the installation directory in the executable files
sed -i "s@####INSTALLATION_DIRECTORY####@$d_INST@" "$d_INST"/stat_watch_wrap.sh 2> "$v_OUT" || v_FAIL=true
sed -i "s@####INSTALLATION_DIRECTORY####@$d_INST@" "$d_INST"/stat_watch.pl 2> "$v_OUT" || v_FAIL=true
sed -i "s@####INSTALLATION_DIRECTORY####@$d_INST@" "$d_INST"/scripts/fold_out.pl 2> "$v_OUT" || v_FAIL=true
sed -i "s@####INSTALLATION_DIRECTORY####@$d_INST@" "$d_INST"/scripts/escape.pl 2> "$v_OUT" || v_FAIL=true
sed -i "s@####INSTALLATION_DIRECTORY####@$d_INST@" "$d_INST"/tests/test.sh 2> "$v_OUT" || v_FAIL=true
if [[ "$v_FAIL" == true ]]; then
	echo "Failed correctly set the installation directory for executable files"
	exit 1
fi

### Get all of the appropriate permissions in place
chmod 700 "$d_INST"/stat_watch.pl 2> "$v_OUT" || v_FAIL=true
chmod 700 "$d_INST"/stat_watch_wrap.sh 2> "$v_OUT" || v_FAIL=true
chmod 700 "$d_INST"/scripts/fold_out.pl 2> "$v_OUT" || v_FAIL=true
chmod 700 "$d_INST"/scripts/escape.pl 2> "$v_OUT" || v_FAIL=true
chmod 700 "$d_INST"/scripts/db_watch.sh 2> "$v_OUT" || v_FAIL=true
chmod 700 "$d_INST"/tests/test.sh 2> "$v_OUT" || v_FAIL=true
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
rm -rf "$d_PROGRAM" "$d_INST"_old 2> "$v_OUT"

echo "Installed successfully"
