use warnings;
use strict;

package SWBackup;

my $v_captured_md5;
my @v_captured_stats;
my $b_do_backup;

sub fn_backup_initial {
### Given a Stat Watch report, backup the files within that match the "BackupR" and "Backup+" control strings
### $_[0] is the report
	my $v_file = $_[0];
	$Main::b_md5_all = 0;
	my @v_lines = &Main::fn_diff_check_lines(undef, 1, $v_file);
	for my $_line (@v_lines) {
		chomp($_line);
		if ( $_line =~ m/^(Maximum depth reached at |Processing: )'/ ) {
			next;
		}
		my @v_file = split( m/'/, $_line );
		$_line = pop(@v_file);
		shift(@v_file);
		my $v_file = join( "'", @v_file );
		my @v_line = split( m/ -- /, $_line );
		if ( scalar(@v_line) == 8 ) {
			if ( length($v_line[7]) == 32 ) {
				### If there's an md5sum, turn on md5sum use
				$Main::b_md5_all = 1;
			}
		}
		fn_backup_file($v_file, $Main::d_backup);
		$Main::b_md5_all = 0;
	}
}

sub fn_check_retention {
### Given the name of a backed-up file, check to ensure that there aren't old copies that exceed the retention limits. If there are, remove them
### $_[0] is the full path to that file in the backup directory, but with the trailing underscore and timestamp removed
	my $v_file = $_[0];
	my @v_dirs = split( m/\//, $v_file );
	my $v_name = pop(@v_dirs);
	my $v_dir = join( '/', @v_dirs );
	my @v_files = fn_list_backups($v_name, $v_dir);
	### Sort the matching files in reverse
	@v_files = sort {$b cmp $a} @v_files;
	### skip over the most recent X files, where X is the retention count
	my $v_count = scalar(@v_files) - 1;
	if ( $Main::v_retention_max_copies > -1 ) {
		### Go through the backups from oldest to newest; remove the ones that are outside of the parameters
		while ( $v_count >= $Main::v_retention_max_copies ) {
			my $v_file = $v_dir . "/" . $v_files[$v_count];
			### Get the string of numbers from the end of the file name
			my $v_stamp = (split( m/_/, $v_files[$v_count] ))[-1];
			### Note, because of the added digit, everything gets multiplied by 10
			if ( ((time() * 10) - $v_stamp) > (864000 * $Main::v_retention_min_days) ) {
				### Delete anything outside of the retention count that's too old and that doesn't have a "_hold" file
				if ( ! -f $v_file . "_hold" ) {
					my $v_file_escape = &SWEscape::fn_escape_filename($v_file);
					&Main::fn_log("Removing backed-up file " . $v_file_escape . "\n");
					unlink( $v_file );
					if ( -f $v_file . "_comment" ) {
						unlink( $v_file . "_comment" );
					}
					if ( -f $v_file . "_stat" ) {
						unlink( $v_file . "_stat" );
					}
					if ( -f $v_file . "_md5" ) {
						unlink( $v_file . "_md5" );
					}
					if ( -f $v_file . "_pointer" ) {
						unlink( $v_file . "_pointer" );
					}
				} elsif ( -f $v_file . "_pointer" ) {
				### If this backup would have been deleted but for the fact that there's a hold file, AND this backup is a pointer
				### If a pointer backup is held, we need to make sure that the content it points to does not get rotated out
					### Find the file that it points to
					my $f_content = fn_backup_details($v_file, 2);
					my $v_content_stamp = (split( m/_/, $f_content ))[-1];
					### If the content file is at risk of being deleted, replace this pointer file with content
					### Note, because of the added digit, everything gets multiplied by 10
					if ( ((time() * 10) - $v_content_stamp) > (864000 * $Main::v_retention_min_days) && ! -f $f_content . "_hold" ) {
						unlink($v_file);
						### This should be the ONLY instance where a file with a newer stamp is pointing to a file with an older stamp
						### (And it will remedy itself as pruning continues)
						fn_create_pointer($f_content, $v_file);
						unlink($v_file . '_pointer');
					} elsif ($v_stamp > $v_content_stamp) {
						### In the edge case where two pointer backups were being held, and the file they were pointing to is going to be deleted,
						### The content will initially end up with the older of the two backup stamps
						### This is where we fix it
						unlink($v_file);
						fn_create_pointer($f_content, $v_file);
						unlink($v_file . '_pointer');
					}
				}
			}
			$v_count--;
		}
	}
}

sub fn_prune_backups {
### This is the main function that's run with the "--prune" option
### $_[0] is the backup directory
	my $v_dir = $_[0];
	if ($Main::b_verbose) {
		my $v_dir_escape = &SWEscape::fn_escape_filename($v_dir);
		print STDERR "Directory: " . $v_dir_escape . "\n";
	}
	if ( -e $v_dir && -d $v_dir ) {
		### Open the directory and get a file list
		if ( opendir my $fh_dir, $v_dir ) {
			my @files = readdir $fh_dir;
			closedir $fh_dir;
			my @dirs;
			my @files2;
			for my $_file (@files) {
				if ( $_file eq "." || $_file eq ".." || $_file eq "__origin_path" ) {
					next;
				} elsif ( -d ($v_dir . "/" . $_file) && ! -l ($v_dir . "/" . $_file) ) {
					push( @dirs, ($v_dir . "/" . $_file) );
					next;
				} elsif ( $_file =~ m/_(hold|comment|stat|md5|pointer)$/ ) {
					### If there's a comment or ctime file present, but the base file isn't there anymore, remove it
					$_file = $v_dir . "/" . $_file;
					my $v_base = $_file;
					$v_base =~ s/_(hold|comment|stat|md5|pointer)$//;
					if ( ! -f $v_base ) {
						unlink( $_file );
					}
					next;
				}
				### Only the actual backup files should still be present at this point
				$_file =~ s/_[0-9]+$//;
				push( @files2, $_file );
			}
			@files = &Main::fn_uniq(@files2);
			for my $_file (@files) {
				$_file = $v_dir . "/" . $_file;
				fn_check_retention($_file);
			}
			for my $_dir (@dirs) {
			### For each of the directories we found, go through RECURSIVELY!
				fn_prune_backups($_dir);
			}
		}
	}
}

sub fn_get_backup_name {
### Given a backup directory and a file name (without full path) return an appropriate name for a backup, and just the stamp
	my $v_dir = $_[0];
	my $v_name = $_[1];
	### Determine the file name we'll use for the new backup
	my $v_time = time();
	my $c = 0;
	no warnings;
	while ( -f $v_dir . "/" . $v_name . "_" . $v_time . $c ) {
	### The objective here is to allow us to perform two backups of a file within the same second. That alone is an edge case - the thought of us doing ten will probably never occur
		use warnings;
		$c++;
		no warnings;
		if ( $c == 10 ) {
			### We should probably never get this far, but if we do, just wait until the next second
			use warnings;
			$c = 0;
			sleep 1;
		}
	}
	use warnings;
	return( ($v_dir . "/" . $v_name . "_" . $v_time . $c), ($v_time . $c) );
}

sub fn_backup_file {
### Check to make sure that a file matches the desired regex, then make a copy of the file
### $_[0] is the file we're copying, $_[1] is the backup directory
	my $v_file = $_[0];
	my $d_backup = $Main::d_backup;
	if ( $_[1] ) {
		$d_backup = $_[1];
	}
	my $b_continue;
	if ( ! -f $v_file && ! -l $v_file ) {
		return;
	}
	if ($b_do_backup) {
		$b_continue = 1;
	}
	if ( ! $b_continue ) {
		for my $_string (@Main::v_backup_plus) {
			if ( $v_file eq $_string ) {
				$b_continue = 1;
				last;
			}
		}
	}
	if ( ! $b_continue ) {
		for my $_string (@Main::v_backupr) {
			if ( $v_file =~ m/$_string/ ) {
				$b_continue = 1;
				last;
			}
		}
	}
	if ($b_continue) {
		my @v_dirs = split( m/\//, $v_file );
		shift(@v_dirs); ### this will have been empty
		my $v_name = pop(@v_dirs);
		my $v_origin_dir = '/' . join( '/', @v_dirs );
		for my $_dir (@v_dirs) {
			$d_backup .= "/" . $_dir;
			if ( ! -d $d_backup ) {
				mkdir( $d_backup );
				chmod( 0700, $d_backup );
			}
		}
		my $v_file_escape = &SWEscape::fn_escape_filename($v_file);
		if ( -d $d_backup ) {
			( my $f_content, my $b_stats ) = fn_compare_backup($v_file, $d_backup);
			if ( $f_content && $b_stats ) {
				### The current backup matches; no need to create a new one
				return( $f_content );
			}

			( my $f_backup, my $v_stamp ) = fn_get_backup_name( $d_backup, $v_name );

			my $fh_write;
			if ( $f_content ) {
				### If the content matches, but the stats do not, move the old content to the new stamp
				fn_create_pointer( $f_content, $f_backup );
			} else {
				### Copy the file
				system( "cp", "-a", $v_file, $f_backup );
			}

			### Test if the files was successfully copied
			if ( -f $f_backup || -l $f_backup ) {
				if ( open( $fh_write, ">", $f_backup . "_stat" ) ) {
					print $fh_write join( ' -- ', @v_captured_stats );
					close($fh_write);
				}

				undef @v_captured_stats;
				### Save the path to the original directory
				if ( ! -f $d_backup . "/__origin_path" && open( $fh_write, ">", $d_backup . "/__origin_path" ) ) {
					print $fh_write $v_origin_dir;
					close($fh_write);
				}
				if ($Main::b_verbose) {
					my $f_backup_escape = &SWEscape::fn_escape_filename($f_backup);
					print STDERR $v_file_escape . " -> " . $f_backup_escape . "\n";
				}
				if ( $f_content ) {
					&Main::fn_log("Backed up changed to file stats for file " . $v_file_escape . "\n");
				} else {
					&Main::fn_log("Backed up file " . $v_file_escape . "\n");
				}
				if ($Main::b_retention) {
					fn_check_retention( $d_backup . "/" . $v_name );
				}

				### If the content different and we captured an md5sum, write it
				if ( ! $f_content && $v_captured_md5 ) {
					### If we captured the md5sums earlier, might as well hold on to them
					if ( open( $fh_write, ">", $f_backup . "_md5" ) ) {
						print $fh_write $v_captured_md5;
						close($fh_write);
					}
					undef $v_captured_md5;
				}
				return $f_backup;
			}
		}
		&Main::fn_log("Failed to backup file " . $v_file_escape . "\n");
		if ($Main::b_verbose) {
			print STDERR "Failed to backup file " . $v_file_escape . "\n";
		}
	}
	return 0;
}

sub fn_list_backups {
### Given a file name (without path) and a directory, return an array of all backup files in that directory
### $_[0] is the file name, $_[1] is the directory
	my $v_name = $_[0];
	my $v_dir = $_[1];
	my @v_files;
	### Open the directory and find all matching files
	if ( opendir my $fh_dir, $v_dir ) {
		my @files = readdir $fh_dir;
		closedir $fh_dir;
		my $re_name = qr/^\Q$v_name\E_[0-9]+$/;
		for my $_file (@files) {
			if ( $_file =~ m/$re_name/ ) {
				push( @v_files, $_file );
			}
		}
	}
	return @v_files;
}

sub fn_file_stats {
### Given a file name, return stats for that file
	my @v_stats1;
	if ( -l $_[0] ) {
		@v_stats1 = (lstat($_[0]))[2,4,5,7,9,10];
	} else {
		@v_stats1 = (stat($_[0]))[2,4,5,7,9,10];
	}
	return(@v_stats1)
}

sub fn_read_first_line {
### Given the name of a file that we only want to read the frst line from, return that first line
	my $v_return;
	if ( -f $_[0] && open( my $fh_read, "<", $_[0] ) ) {
		while (<$fh_read>) {
			$v_return = $_;
			chomp( $v_return );
			last;
		}
		close($fh_read);
	}
	return( $v_return );
}

sub fn_compare_backup {
### Compare an existing backup to the files it was taken from
### This will return two values:
	### 1) either the number "0" or the name of the backup file with matching content
	### 2) "0" to indicate that the permissions and stamps do not match, "1" to indicate that they do
### $_[0] is the file in-place, $_[1] is the directory that it's in
	my $v_file = $_[0];
	my $v_dir = $_[1];

	### Get the stats for the file currently present
	my @v_stats1 = fn_file_stats($v_file);
	### Hold on to the file stats in case we need them
	@v_captured_stats = @v_stats1;

	my @v_dirs = split( m/\//, $v_file );
	my $v_name = pop(@v_dirs);
	my @v_files = fn_list_backups($v_name, $v_dir);
	if ( ! @v_files ) {
		return( 0, 0 );
	} else {
		@v_files = sort {$b cmp $a} @v_files;

		### The last one should be the most recent backup - the one we want to compare to
		my $v_file2 = $v_dir . "/" . $v_files[0];

		### Get the stats for the backup
		my @v_stats2;
		my $v_stats = fn_read_first_line( $v_file2 . "_stat" );
		if ($v_stats) {
			@v_stats2 = split( m/ -- /, $v_stats );
		}

		### Find if the stats are different
		my $b_perms;
		my $b_size;
		my $b_stamps;
		my $c;
		for ($c=0; $c < scalar(@v_stats1); $c++) {
			if ( ! defined $v_stats2[$c] || $v_stats1[$c] != $v_stats2[$c] ) {
				if ( $c == 0 || $c == 1 || $c == 2 ) {
					$b_perms = 1;
				} elsif ( $c == 3 ) {
					$b_size = 1;
				} else {
					$b_stamps = 1;
				}
			}
		}

		### Assess how we need to respond based on differences in the stats
		if ( ! $b_perms && ! $b_size && ! $b_stamps ) {
			### If everything is the same, return the name of the most recent backed up file
				### Note, while it's possible for the ctime and size to be the same and the content to still be different,
				### this is such an extreme edge case, that performing an md5sum check for it every time is ridiculous
			return( $v_file2, 1 );
		} elsif ( $b_size ) {
			### If the size of the file changed, we know that both its content and ctime should be different
			return( 0, 0 );
		} else {
			### We do not know whether or not content is different - better get md5sums!
			if ($Main::b_use_md5) {
				### Start by getting the md5sum of the file in place
				$v_captured_md5 = &SWmd5::get_md5($v_file);

				### Then get the md5sum of the backed up file
				my $v_md5_backup = fn_read_first_line($v_file2 . "_md5");
				if ( ! $v_md5_backup ) {
					### If it's not there, Maybe the backup is a pointer and we can find it elsewhere
					my $f_content = fn_backup_details($v_file2, 2);
					if ( $f_content ne $v_file2 ) {
						$v_md5_backup = fn_read_first_line($f_content . "_md5");
					}
					if ( ! $v_md5_backup ) {
						### Otherwise, we'll just have to GET IT OUR SELVES
						$v_md5_backup = &SWmd5::get_md5($f_content);
						if ( open( my $fh_write, ">", $v_file2 . "_md5" ) ) {
							print $fh_write $v_md5_backup;
							close($fh_write);
						}
					}
				}

				### Compare them
				if ( $v_captured_md5 eq $v_md5_backup ) {
					### The content is the same, but something else is different
					undef $v_captured_md5;
					return( $v_file2, 0 );
				} else {
					### The content is different!
					return( 0, 0 );
				}
			} else {
				### We don't know if the content changed. Better back it up just to be safe
				return( 0, 0 );
			}
		}
	}
}

sub fn_find_backup {
### Given the display name of a backup or the full path to a backup, find the full path to that backup
	my $v_disp = $_[0];
	$v_disp = &Main::fn_test_file($v_disp);
	my $b_maybe_full_path;
	if ( -f $v_disp ) {
		$b_maybe_full_path = 1;
	}
	my @v_backup_dirs;
	if ($Main::d_backup) {
		@v_backup_dirs = ($Main::d_backup);
	}

	### Find all of the backup directories that have been used
	if ( ! -d $Main::d_working ) {
		mkdir( $Main::d_working );
	}
	### Open the list and read from it
	if ( -f $Main::d_working . "/backup_locations" ) {
		if ( open( my $fh_read, "<", $Main::d_working . "/backup_locations" ) ) {
			while (<$fh_read>) {
				my $_line = $_;
				chomp($_line);
				if ( ! $Main::d_backup || $_line ne $Main::d_backup ) {
					push( @v_backup_dirs, $_line );
				}
			}
			close($fh_read);
		}
	}

	my @v_dirs = split( m/\//, $v_disp );
	shift(@v_dirs); ### this will have been empty
	my $v_name = pop(@v_dirs);
	### Go through each backup directory to see if this file is present
	DBACKUP: for my $d_backup (@v_backup_dirs) {
		if ( $b_maybe_full_path && $v_disp =~ m/^\Q$d_backup\E/ ) {
			### It turns out that we were given the full path to begin with
			return( $v_disp );
		}
		for my $_dir (@v_dirs) {
			$d_backup .= "/" . $_dir;
			if ( ! -d $d_backup ) {
				next DBACKUP;
			}
		}
		my $v_return = $d_backup . '/' . $v_name;
		if ( -l $v_return || -f $v_return ) {
			### If we find a file that matches the name, return it
			return( $v_return );
		}
	}
	return;
}

sub fn_restore {
### Given the display name or full path to a backup, restore it
	my $v_disp = $_[0];

	### Find the location of the backup and the original file path
	my $f_backup = fn_find_backup($v_disp);
	if ( ! $f_backup ) {
		print STDERR "No such backup " . &SWEscape::fn_escape_filename($v_disp) . "\n";
		exit 1
	}
	( my $f_stats, my $f_origin, my $f_content, my $d_backup, my $v_name, my $d_backup2 ) = fn_backup_details($f_backup);

	### Extract the stats
	my $v_stats = fn_read_first_line($f_stats);
	if ( ! $v_stats ) {
		##### If we're trying to restore a backup that doesn't have a stat file... should we even allow that?
		print STDERR "No stat data for this backup\n";
		exit 1;
	}
	my @v_stats = split( m/ -- /, $v_stats );

	### Make a backup of the file as it currently is, then remove it
	$b_do_backup = 1;
	$Main::b_retention = 0;
	if ( -e $f_origin ) {
		my $f_backup2 = fn_backup_file($f_origin, $d_backup2);

		if ( ! $f_backup2 ) {
			print STDERR "Failed to create backup of " . &SWEscape::fn_escape_filename($f_origin) . ". File left as-is.\n";
			exit 1;
		}
		unlink($f_origin)
	}

	### Restore the backup
	system( "cp", "-a", $f_content, $f_origin );
	chmod( oct( sprintf( "%04o", $v_stats[0] & 07777) ), $f_origin );
	chown( $v_stats[1], $v_stats[2], $f_origin );
	utime( $v_stats[4], $v_stats[4], $f_origin );
	@v_stats = fn_file_stats($f_origin);

	### Create a new backup showing that the file has been restored
	( my $f_backup2, my $v_stamp ) = fn_get_backup_name( $d_backup, $v_name );
	fn_create_pointer($f_content, $f_backup2, $v_stamp);
	if ( $f_content ne $f_backup ) {
		fn_write_pointer( $f_backup, $v_stamp );
	}
	my $v_stamp2 = substr((split( m/_/, $f_backup ))[-1], 0, -1);
	$v_stamp2 = &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stamp2) );
	my $fh_write;
	if ( open( $fh_write, ">>", $f_backup2 . "_comment" ) ) {
		print $fh_write "Restored from backup taken at " . $v_stamp2 . "\n";
		close($fh_write);
	}
	if ( open( $fh_write, ">", $f_backup2 . "_stat" ) ) {
		print $fh_write join( ' -- ', @v_stats );
		close($fh_write);
	}
}

sub fn_create_pointer {
### Given the full path to a file where content is currently, and the full path to a file where the content needs to be
	### And optionally, the stamp for the new location
### Move the content, and replace it with a pointer file
	my $v_orig = $_[0];
	my $v_new = $_[1];
	my $v_stamp = ( $_[2] || '' );
	no warnings;
	if ( -e $v_new ) {
		use warnings;
		print STDERR "There is already a file at " . &SWEscape::fn_escape_filename($v_new) . "\n";
		exit 1;
	}
	use warnings;
	if ( ! $v_stamp ) {
		$v_stamp = (split( m/_/, $v_new ))[-1];
	}
	rename( $v_orig, $v_new );
	if ( -e $v_new ) {
		fn_write_pointer( $v_orig, $v_stamp );
		no warnings;
		if ( -f $v_orig . '_md5' ) {
			use warnings;
			system( "cp", "-a", ($v_orig . '_md5'), ($v_new . '_md5') );
		}
		use warnings;
	} else {
		print STDERR "Failed to move file to " . &SWEscape::fn_escape_filename($v_new) . "\n";
		exit 1;
	}
}

sub fn_write_pointer {
### Given the name of a backup file, and the stamp of a file it should point to, write pointer files
	my $fh_write;
	if ( open( $fh_write, ">", $_[0] ) ) {
		print $fh_write $_[1];
		close($fh_write);
	}
	if ( open( $fh_write, ">", $_[0] . "_pointer" ) ) {
		print $fh_write $_[1];
		close($fh_write);
	}
}

sub fn_backup_details {
### Given the full path to a backed up file, return the following:
	### 0) It's stat file
	### 1) The original path
	### 2) The content file (I.E. follow any pointers to their source)
	### 3) The backup directory that the file will go in
	### 4) The name of the original file (without path)
	### 5) The path to the root of the backup directory
### Optional second argument: the specific array numbers for the desired items
	my $f_backup = $_[0];
	my @v_return_nums;
	if ( defined $_[1] && defined $_[2] ) {
		shift( @_ );
		@v_return_nums = @_;
	} elsif ( defined $_[1] ) {
		push( @v_return_nums, $_[1] );
	}
	my $f_stat = $f_backup . '_stat';
	my @v_path = split( m/\//, $f_backup );
	my $v_name = pop(@v_path);
	my $d_backup = join( '/', @v_path );
	my $v_path = fn_read_first_line( $d_backup . '/__origin_path' );
	my $d_backup2 = $d_backup;
	$d_backup2 =~ s/\Q$v_path\E$//;
	$v_name =~ s/_[0-9]+//;
	my $f_content = fn_follow_pointers($f_backup, $d_backup, $v_name);
	my $f_orig = $v_path . '/' . $v_name;

	my @v_return = ( $f_stat, $f_orig, $f_content, $d_backup, $v_name, $d_backup2 );
	if (! @v_return_nums) {
		return( @v_return );
	} elsif ( scalar(@v_return_nums) == 1 ) {
		return( $v_return[$v_return_nums[0]] );
	} else {
		my @v_return2;
		for my $i (@v_return_nums) {
			push( @v_return2, $v_return[$i] );
		}
		return( @v_return2 );
	}
}

sub fn_follow_pointers {
### Given the full path to a backed up file, the full path to the directory it's in, and the original file name, follow all pointers until the content is reached
	my $v_file = $_[0];
	my $d_backup = $_[1];
	my $v_name = $_[2];
	my $v_file2 = $v_file;
	my $v_file3 = $v_file;
	no warnings;
	if ( -f $v_file . "_pointer" ) {
		use warnings;
		$v_file2 = $d_backup . '/' . $v_name . '_' . fn_read_first_line($v_file . "_pointer");
		$v_file3 = fn_follow_pointers($v_file2, $d_backup, $v_name);
		### Eliminate pointer chains by pointing them to the most recent file
		if ( $v_file ne $v_file3 ) {
			my $v_stamp = (split( m/_/, $v_file3 ))[-1];
			fn_write_pointer( $v_file, $v_stamp );
		}
	}
	use warnings;
	return($v_file3);
}

sub fn_list_file {
### Given a file name, list the backups that are available for it
### $_[0] is the full path for the file
	my $v_file = $_[0];
	my @v_backup_dirs;
	if ($Main::d_backup) {
		@v_backup_dirs = ($Main::d_backup);
	}
	{
	### Find all of the backup directories that have been used
		if ( ! -d $Main::d_working ) {
			mkdir( $Main::d_working );
		}
		### Open the list and read from it
		if ( -f $Main::d_working . "/backup_locations" ) {
			if ( open( my $fh_read, "<", $Main::d_working . "/backup_locations" ) ) {
				while (<$fh_read>) {
					my $_line = $_;
					chomp($_line);
					if ( ! $Main::d_backup || $_line ne $Main::d_backup ) {
						push( @v_backup_dirs, $_line );
					}
				}
				close($fh_read);
			}
		}
	}
	my @v_dirs = split( m/\//, $v_file );
	shift(@v_dirs); ### this will have been empty
	my $v_name = pop(@v_dirs);
	my $d_orig = '/' . join( '/', @v_dirs );
	my %v_files;
	### Go through each backup directory to find instances where this file has been backed up
	DBACKUP: for my $d_backup (@v_backup_dirs) {
		for my $_dir (@v_dirs) {
			$d_backup .= "/" . $_dir;
			if ( ! -d $d_backup ) {
				next DBACKUP;
			}
		}
		my @v_files2 = fn_list_backups($v_name, $d_backup);
		for my $_file (@v_files2) {
			my $v_stamp = (split( m/_/, $_file ))[-1];
			$_file = $d_backup . "/" . $_file;
			$v_files{$v_stamp} = $_file
		}
	}
	### Output the details
	my $v_file_escape = &SWEscape::fn_escape_filename($v_file);
	print "\nAvailable Backups for " . $v_file_escape . ":\n";
	if (%v_files) {
		my @v_files = sort {$a cmp $b} keys( %v_files );
		for my $v_stamp (@v_files) {
			### Get the string of numbers from the end of the file name, then trim off the last number - this is the timestamp
			my $v_file = $v_files{$v_stamp};
			my $v_disp_name = $d_orig . '/' . $v_name . '_' . $v_stamp;
			$v_stamp = substr( $v_stamp, 0, -1);
			$v_stamp = &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stamp) );

			### Get the size of the file
			my $v_size;
			### Apparently earlier versions of perl error if you ask about a file that has a new line character and turns out to be not present. Turning off warnings fixes this.
			no warnings;
			if ( -f $v_file . "_stat" ) {
				if ( ! -f $v_file . "_pointer" ) {
					use warnings;
					### If this isn't a pointer backup, it's easier to just get the stat
					if ( -l $v_file ) {
						$v_size = (lstat($v_file))[7];
					} else {
						$v_size = (stat($v_file))[7];
					}
				} else {
					use warnings;
					### If it's a pointer backup, easier to get it from the _stat file
					$v_size = (split( m/ -- /, fn_read_first_line( $v_file . "_stat" ) ))[3];
				}		
			} else {
				##### should we even bother listing it if there's no stat file
				next;
			}

			use warnings;
			my $v_file_escape = &SWEscape::fn_escape_filename($v_disp_name);
#			my $v_file_escape = &SWEscape::fn_escape_filename($v_file);
			print "  " . $v_file_escape . " -- Timestamp: " . $v_stamp . " -- " . $v_size . " bytes";
			no warnings;
			if ( -f $v_file . "_hold" ) {
				use warnings;
				print " -- HELD"
			}
			use warnings;
			print "\n";
			no warnings;
			if ( -f $v_file . "_comment" ) {
				use warnings;
				&Main::fn_print_files( "    - ", $v_file . "_comment" );
			}
			use warnings;
		}
	} else {
		print "There are no backups of this file\n"
	}
}

sub fn_compare_contents {
### Given a backup file, show how it compares to the existing file
### If a second file is given, show how the file compares to that file instead
### If the first file is just a regular file, and the SECOND file is a backup... yeah we can do that too.
	my $v_disp1 = $_[0];

	### Find the location of the backup and the original file path
	my $f_comp1 = fn_find_backup($v_disp1);
	my $f_stats1;
	my $f_origin;
	my $f_content1;
	if ( ! $f_comp1 && -f $v_disp1 ) {
		$f_comp1 = $v_disp1;
		$f_content1 = $v_disp1
	} elsif ( ! $f_comp1 ) {
		print STDERR "No such backup " . &SWEscape::fn_escape_filename($v_disp1) . "\n";
		exit 1;
	} else {
		( $f_stats1, $f_origin, $f_content1 ) = fn_backup_details($f_comp1, 0, 1, 2);
	}

	### And figure out what we're comparing it to
	my $v_disp2 = $f_origin;
	my $f_comp2 = $f_origin;
	my $f_content2 = $f_origin;
	my $f_stats2;
	if ( defined $_[1] ) {
		my $v_file = fn_find_backup($_[1]);
		if ( $v_file ) {
			$f_comp2 = $v_file;
			$v_disp2 = $_[1];
			( $f_stats2, $f_content2 ) = fn_backup_details($f_comp2, 0, 2);
		} elsif ( -f $_[1] ) {
			$f_comp2 = $_[1];
			$v_disp2 = $_[1];
			$f_content2 = $_[1];
		} else {
			print STDERR "No such file " . &SWEscape::fn_escape_filename($_[1]) . "\n";
			exit 1;
		}
	} elsif ( ! $f_origin ) {
		print STDERR "Nothing to compare " . &SWEscape::fn_escape_filename($v_disp1) . "against \n";
	}

	### Get the stats for both files
	my @v_stats1;
	if ( ! $f_stats1 ) {
		@v_stats1 = fn_file_stats($f_content1);
	} else {
		@v_stats1 = split( m/ -- /, fn_read_first_line($f_stats1) );
	}
	my @v_stats2;
	if ( ! $f_stats2 ) {
		@v_stats2 = fn_file_stats($f_comp2);
	} else {
		@v_stats2 = split( m/ -- /, fn_read_first_line($f_stats2) );
	}

	### Begin output
	print "\n";
	print "     Comparing\n" . &SWEscape::fn_escape_filename($f_comp1) . "\n     To\n" . &SWEscape::fn_escape_filename($f_comp2) . "\n\n";

	print "     Type and Permissions:\n" . &Main::fn_format_perms($v_stats1[0]) . "  >  " . &Main::fn_format_perms($v_stats2[0]) . "\n";
	print "     User:\n" . $v_stats1[1] . "  >  " . $v_stats2[1] . "\n";
	print "     Group:\n" . $v_stats1[2] . "  >  " . $v_stats2[2] . "\n";
	print "     File Size:\n" . $v_stats1[3] . " bytes  >  " . $v_stats2[3] . " bytes\n";
	print "     Modify Time:\n" . &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stats1[4]) ) . "  >  " . &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stats2[4]) ) . "\n";
	print "     Change Time:\n" . &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stats1[5]) ) . "  >  " . &Main::strftime( '%Y-%m-%d %T %z', localtime($v_stats2[5]) ) . "\n\n";

	### Now just diff the files
	print "     Content:\n\n";
	my $diff1_escape = &SWEscape::fn_shell_escape_filename($f_content1);
	my $diff2_escape = &SWEscape::fn_shell_escape_filename($f_content2);
	print `diff $diff1_escape $diff2_escape 2>&1`;
}

sub fn_single_backup {
### Backup a single file
### $_[0] is the full path to the file, $_[1] is the path to the backup directory, $_[2] is boolean whether or not to hold the backup, $_[3] is a comment for the backup
	my $v_file = $_[0];
	my $d_backup = ( $_[1] || $Main::d_backup );
	my $b_hold = $_[2];
	my $v_comment;
	if ( defined $_[3] ) {
		$v_comment = $_[3];
	}
	$b_do_backup = 1;
	my $f_backup = fn_backup_file( $v_file, $d_backup );
	if ( $b_hold && ! -f $f_backup . "_hold" ) {
		if ( open( my $fh_write, ">>", $f_backup . "_hold" ) ) {
			print $fh_write time();
			close($fh_write);
		}
	}
	if ($v_comment) {
		if ( open( my $fh_write, ">>", $f_backup . "_comment" ) ) {
			print $fh_write $v_comment . "\n";
			close($fh_write);
		}
	}
	return $f_backup;
}

sub fn_hold {
### Given a backup file, create a hold for that backup
	my $v_disp = shift(@_);

	### Find the location of the backup and the original file path
	my $f_backup = fn_find_backup($v_disp);
	if ( ! $f_backup ) {
		print STDERR "No such backup " . &SWEscape::fn_escape_filename($v_disp) . "\n";
		exit 1
	}

	if ( open( my $fh_write, ">", $f_backup . "_hold" ) ) {
		close($fh_write);
	}
	if ( defined $_[0] && $_[0] eq "--comment" && defined $_[1] ) {
		fn_comment($v_disp, $_[1]);
	}
}

sub fn_unhold {
### Given a backup file; remove the hold for that backup
	my $v_disp = $_[0];

	### Find the location of the backup and the original file path
	my $f_backup = fn_find_backup($v_disp);
	if ( ! $f_backup ) {
		print STDERR "No such backup " . &SWEscape::fn_escape_filename($v_disp) . "\n";
		exit 1
	}
	if ( -f $f_backup . '_hold' ) {
		unlink $f_backup . '_hold'
	}
}

sub fn_comment {
### Given a backup file, add a comment to that backup
	my $v_disp = shift(@_);
	my $v_comment = shift(@_);

	### Find the location of the backup and the original file path
	my $f_backup = fn_find_backup($v_disp);
	if ( ! $f_backup ) {
		print STDERR "No such backup " . &SWEscape::fn_escape_filename($v_disp) . "\n";
		exit 1
	}
	if ($v_comment) {
		if ( open( my $fh_write, ">>", $f_backup . "_comment" ) ) {
			print $fh_write $v_comment . "\n";
			close($fh_write);
		}
	}
	if ( defined $_[0] && $_[0] eq "--hold" ) {
		fn_hold($v_disp);
	}
}

1;
