use warnings;
use strict;

### Output details regarding a stat watch report

package SWReportDetails;

my $b_all = 0;
my $f_report;
my @v_files;
my @v_files_temp;

our %v_users;
our %v_groups;

sub fn_rd_out {
### Given a report file, output when each section was started as well as the stats on any files requested
	my $v_processing;
	my $v_timestamp = '';
	my $re_multiline;
	if ( open( my $fh_read, "<", $f_report ) ) {
		while (<$fh_read>) {
			my $v_line = $_;
			if ( $v_line =~ m/^Processing:/ ) {
				chomp($v_line);
				### Each time we see a processing line, we have to re-do the ignore strings to make sure that we're not ignoring something we shouldn't
				$v_processing = (split( m/'/, $v_line, 2 ))[1];
				### Trade timestamps
				$v_timestamp = $v_processing;
				$v_timestamp =~ s/^.*\s([0-9]+)$/$1/;
				### create the regex for the multi-line
				$re_multiline = qr/_mlfn_\Q$v_timestamp\E/;
				$v_processing =~ s/' - [0-9]+$//;
				$v_processing = "Processing of " . &SWEscape::fn_escape_filename($v_processing) . " started at '" . &Main::strftime( '%Y-%m-%d %T %z', localtime($v_timestamp)) . "'\n";
				if ( ! @v_files && ! $b_all ) {
					print $v_processing;
				} elsif ( @v_files ) {
					undef @v_files_temp;
					for my $_file ( @v_files ) {
						my $v_file = &Main::fn_get_file_name( $_file, $v_timestamp );
						push( @v_files_temp, $v_file );
					}
				}
			} elsif ( ! $v_timestamp ) {
				### If we've reached a normal line before we reached a processing line, there's a problem
				print STDERR "File " . &SWEscape::fn_escape_filename($f_report) . " does not appear to be a Stat Watch file\n";
				exit 1;
			} elsif ( $b_all && substr( $v_line, 0, 2 ) eq "'/" ) {
			### If we're outputting all of the file stats, DO IT!
				chomp($v_line);
				my @v_line = split( m/'/, $v_line );

				### Get the stats
				$v_line = pop(@v_line);
				### Lines for files begin with a single quote, so after the split, there will be an empty string at the start of the array. Let's get rid of it
				shift(@v_line);

				### Correct the file name if it's multi line
				my $v_file = join( "'", @v_line );
				if ( $v_file =~ m/$re_multiline/ ) {
					$v_file =~ s/$re_multiline/\n/g;
				}

				### If we have not yet output the processing details, do so
				if ( $v_processing ) {
					print "\n" . $v_processing . "\n";
					$v_processing = undef;
				}
				fn_stat_file( $v_file, $v_line );
			} elsif ( @v_files && substr( $v_line, 0, 2 ) eq "'/" ) {
			### If we're only doing individual files, check to see if it's one of those files
				for ( my $i = 0; $i < @v_files_temp; $i++ ) {
					if ( $v_line =~ m/^'\Q$v_files_temp[$i]\E'[^']+$/ ) {
						### We no longer need to search for this file, so remove it
						splice( @v_files_temp, $i, 1);
						splice( @v_files, $i, 1);

						chomp($v_line);
						my @v_line = split( m/'/, $v_line );

						### Get the stats
						$v_line = pop(@v_line);
						### Lines for files begin with a single quote, so after the split, there will be an empty string at the start of the array. Let's get rid of it
						shift(@v_line);

						### Correct the file name if it's multi line
						my $v_file = join( "'", @v_line );
						if ( $v_file =~ m/$re_multiline/ ) {
							$v_file =~ s/$re_multiline/\n/g;
						}

						### If we have not yet output the processing details, do so
						if ( $v_processing ) {
							print "\n" . $v_processing . "\n";
							$v_processing = undef;
						}
						fn_stat_file( $v_file, $v_line );

						### If we've matched the file, no need to check the other files
						last;
					}
				}
				if ( ! @v_files ) {
					### If we've run out of files, no need to process the rest of the lines
					last;
				}
			}
		}
		close($fh_read);
	}
}

sub fn_get_users_groups {
### Parse /etc/passwd and /etc/group for names
	if ( -r '/etc/passwd' && open( my $fh_read, "<", '/etc/passwd' ) ) {
		while (<$fh_read>) {
			( my $v_name, my $v_number ) = (split( m/:/, $_ ))[0,2];
			$v_users{$v_number} = $v_name;
		}
		close($fh_read);
	}
	if ( -r '/etc/group' && open( my $fh_read, "<", '/etc/group' ) ) {
		while (<$fh_read>) {
			( my $v_name, my $v_number ) = (split( m/:/, $_ ))[0,2];
			$v_groups{$v_number} = $v_name;
		}
		close($fh_read);
	}
}

sub fn_get_user_group {
### Given a user number and group number, make sure that it exists
	if ( ! exists $v_users{$_[0]} ) {
		$v_users{$_[0]} = "???";
	}
	if ( ! exists $v_groups{$_[1]} ) {
		$v_groups{$_[1]} = "???";
	}
}

sub fn_stat_file {
### Given the name of a file and the stat line of a file, output stats in a more human readable format
	my $v_file = $_[0];
	my $v_stat = $_[1];

	my $v_md5;
	my @v_line = split( m/ -- /, $v_stat );
	if ( $v_stat =~ m/^ -- / ) {
		shift(@v_line);
	}
	if ( scalar(@v_line) == 7 ) {
		if ( length($v_line[6]) == 32 ) {
			### If there's an md5sum, capture it
			$v_md5 = pop(@v_line);
		} else {
			### I don't know what this is, so get rid of it
			pop(@v_line);
		}
	}
	my $v_ctime = pop(@v_line);
	my $v_mtime = pop(@v_line);
	my $v_size = pop(@v_line);
	my $v_group = pop(@v_line);
	my $v_owner = pop(@v_line);
	my $v_perms = pop(@v_line);
	if ( $v_perms =~ m/^[0-9]+$/ ) {
	### This indicates that the report file was done with internal stat rather than external stat
		$v_ctime = &Main::strftime( '%Y-%m-%d %T %z', localtime($v_ctime) );
		$v_mtime = &Main::strftime( '%Y-%m-%d %T %z', localtime($v_mtime) );
		$v_perms = &Main::fn_format_perms($v_perms);
	}

	### If we have not yet gotten users and groups, do so
	if ( ! %v_users ) {
		fn_get_users_groups();
	}
	fn_get_user_group($v_owner, $v_group);

	### Output the file stats
	print "  FILE: " . &SWEscape::fn_escape_filename($v_file) . "\n";
	print "  SIZE: " . $v_size . " bytes";
	if ( $v_md5 ) {
		print "   MD5 SUM: " . $v_md5;
	}
	print "\n";
	print "ACCESS: " . $v_perms . "  USER: (" . $v_owner . " / " . $v_users{$v_owner} . ")  GROUP: (" . $v_group . " / " . $v_groups{$v_group} . ")\n";
	print "MODIFY: " . $v_mtime . "\n";
	print "CHANGE: " . $v_ctime . "\n";
}

sub fn_rd_parse {
### Parse the command line arguments for report details
	while (@_) {
		my $v_arg = shift(@_);
		if ( $v_arg eq "--all" ) {
			$b_all = 1;
		} elsif ( ($v_arg eq "--file" || $v_arg eq "-f") && defined $_[0] ) {
			my $v_file = &Main::fn_test_file( shift(@_) );
			if ( $v_file ) {
				push( @v_files, $v_file );
			}
		} elsif ( ($v_arg eq "--report" || $v_arg eq "-r") && defined $_[0] ) {
			my $v_report = &Main::fn_test_file( shift(@_), 1, 'f' );
			if ( $v_report ) {
				$f_report = $v_report;
			}
		} else {
			if ( ! defined $f_report ) {
				my $v_report = &Main::fn_test_file( $v_arg, 1, 'f' );
				if ($v_report) {
					$f_report = $v_report;
				}
			} else {
				my $v_file = &Main::fn_test_file( $v_arg );
				if ( $v_file ) {
					push( @v_files, $v_file );
				}
			}
		}
	}
	if (! $f_report) {
		print STDERR "A a report file generated using \`stat_watch --report\` must be specified\n";
		exit
	}
	fn_rd_out();
}

1;
