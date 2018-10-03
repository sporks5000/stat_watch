#! /usr/bin/perl
### Given a directory, get stats for all files and subdirectories
### Useful for seeing what has changed since the last time this was run
### Created by ACWilliams

use strict;
use warnings;

my $v_VERSION = "1.3.2";

use Cwd 'abs_path';
use POSIX 'strftime';

my $v_program = __FILE__;
my $d_program;
my $d_working;

### Arrays to hold files and directories to check against and ignore strings
my @v_dirs;
my @v_ignore;
my @v_rignore;
my @v_star_ignore;
my @v_temp_ignore;
my @v_temp_rignore;
my @v_temp_star_ignore;

### Variables for what's output and to where
my $b_verbose;
my $f_output;
my $fh_output;
my $v_format;
my $f_log;
my $fh_log;

### Various things related to backups
my $d_backup;
my $b_backup;
my @v_backupr;
my @v_backup_plus;
my $v_retention_min_days = 7;
my $v_retention_max_copies = 4;
my $b_retention = 1;

### Other
my @v_time_minus;
my $b_diff_ctime = 1;
my $b_ignore_on_record;
my @v_includes;
my $b_partial_seconds = 1;
my @v_md5;
my @v_md5r;
my $b_use_md5;
my $b_md5_all;
my $v_max_depth = 20;
my $v_cur_depth = 0;
my $v_as_dir;
my $v_current_dir;
my $b_links;
my $b_new_lines;

#===================#
#== Report Output ==#
#===================#

sub fn_check_file {
### Check a file to see if it matches any of the ignore lists
### $_[0] is the full path to the file
	my $v_file = $_[0];
	my $v_file_escape;
	if ($b_verbose) {
		$v_file_escape = fn_escape_filename($v_file);
	}
	for my $_string (@v_temp_ignore){
		if ( $v_file eq $_string ) {
			if ($b_verbose) {
				print STDERR "IGNORED: " . $v_file_escape. "\n";
			}
			return 0;
		}
	}
	for my $_string (@v_temp_rignore) {
		if ( $v_file =~ m/$_string/ ) {
			if ($b_verbose) {
				print STDERR "IGNORED: " . $v_file_escape . "\n";
			}
			return 0;
		}
	}
	for my $_string (@v_temp_star_ignore){
		if ( $v_file =~ m/$_string/ ) {
			if ($b_verbose) {
				print STDERR "IGNORED: " . $v_file_escape . "\n";
			}
			return 0;
		}
	}
	return 1;
}

sub fn_check_md5 {
### Given a file name, if we're supposed to get md5's return the md5. Otherwise, return an empty string
	my $v_file = $_[0];
	if ( $b_use_md5 && (-l $v_file || ! -d $v_file) ) {
		if ($b_md5_all) {
			my $v_md5 = &sw_md5::get_md5($v_file);
			if ( $v_md5 ) {
				$v_md5 = ' -- ' . $v_md5;
			}
			return $v_md5;
		}
		for my $_string (@v_md5) {
			if ( $v_file eq $_string ) {
				my $v_md5 = &sw_md5::get_md5($v_file);
				if ( $v_md5 ) {
					$v_md5 = ' -- ' . $v_md5;
				}
				return $v_md5;
			}
		}
		for my $_string (@v_md5r) {
			if ( $v_file =~ m/$_string/ ) {
				my $v_md5 = &sw_md5::get_md5($v_file);
				if ( $v_md5 ) {
					$v_md5 = ' -- ' . $v_md5;
				}
				return $v_md5;
			}
		}
	}
	return '';
}

sub fn_get_file_name {
### Given the name of a file, appropriately replace new line characters and modify as necessary for a "--record" style report
	my $v_file = $_[0];
	my $v_timestamp = $_[1];
	if ($v_as_dir) {
		$v_file = $v_as_dir . substr( $v_file, length($v_current_dir) );
	}
	if ( $v_file =~ m/\n/ ) {
		$v_file =~ s/\n/_mlfn_$v_timestamp/g;
	}
	return $v_file;
}

sub fn_report_line {
### Given a file name, output the necessary data for a "--record" style report
	my $v_file = $_[0];
	my $v_timestamp = $_[1];
	my $v_file_escape = fn_shell_escape_filename($v_file);
	my $v_line = `stat -c \%A" -- "\%u" -- "\%g" -- "\%s" -- "\%y" -- "\%z $v_file_escape 2> /dev/null`;
	chomp( $v_line );
	$v_line .= fn_check_md5($v_file);
	$v_file = fn_get_file_name($v_file, $v_timestamp);
	print $fh_output "'" . $v_file . "' -- " . $v_line . "\n";
}

sub fn_stat_watch {
### Stat every file in the directory, then dive into directories
### $_[0] is the directory in question; $_[1] is the timestamp associated with this process
	my $v_dir = $_[0];
	my $v_timestamp = $_[1];
	my $c_links = 0;
	if ($b_verbose) {
		my $v_dir_escape = fn_escape_filename($v_dir);
		print STDERR "Directory: " . $v_dir_escape . "\n";
	}
	if ( -e $v_dir && ! -d $v_dir ) {
	### If we were given a file instead of a directory
		my $v_file = $v_dir;
		if ( fn_check_file($v_file) ) {
			if ($b_links) {
				if ( -l $v_file ) {
					print "1 - " . fn_escape_filename($v_file) . "\n";
				}
			} elsif ( $b_new_lines ) {
				if ( $v_file =~ m/[\001-\037\x7F\n]/ ) {
					print fn_escape_filename($v_file) . "\n";
				}
			} else {
				fn_report_line($v_file, $v_timestamp);
			}
		}
	} elsif ( -e $v_dir ) {
		if ( $v_dir eq $v_current_dir && ! $b_links && ! $b_new_lines ) {
			fn_report_line($v_dir, $v_timestamp);
		}
		### Open the directory and get a file list
		if ( opendir my $fh_dir, $v_dir ) {
			my @files = readdir $fh_dir;
			closedir $fh_dir;
			my @dirs;
			for my $_file (@files) {
				if ( $_file ne "." && $_file ne ".." ) {
					my $v_file = $v_dir . "/" . $_file;
					### Make sure that the file doesn't match any of the ignore lists
					if ( ($b_ignore_on_record || (-d $v_file && ! -l $v_file)) && ! fn_check_file($v_file) ) {
						next;
					}
					### Capture it if it's a directory
					if ( -d $v_file && ! -l $v_file ) {
						push( @dirs, $v_file );
					}
					if ($b_links) {
						if ( -l $v_file ) {
							$c_links++;
						}
					} elsif ( $b_new_lines ) {
						if ( $v_file =~ m/[\001-\037\x7F\n]/ ) {
							print fn_escape_filename($v_file) . "\n";
						}
					} else {
						fn_report_line($v_file, $v_timestamp);
					}
				}
			}
			if ( $c_links ) {
				print $c_links . " - " . fn_escape_filename($v_dir) . "\n";
			}
			for my $_dir (@dirs) {
			### For each of the directories we found, go through RECURSIVELY!
				$v_cur_depth++;
				if ( $v_cur_depth <= $v_max_depth ) {
					fn_stat_watch( $_dir, $v_timestamp);
				} else {
					fn_log("Maximum depth reached at " . fn_escape_filename($v_dir) . "\n");
					### If it contains a newline character, then it needs to be processed specially
					my $v_dir_name = fn_get_file_name($_dir, $v_timestamp);
					print $fh_output "Maximum depth reached at '" . $v_dir_name . "' - " . $v_timestamp . "\n";
				}
				$v_cur_depth--;
			}
		}
	}
}

#=====================#
#== Performing diff ==#
#=====================#

sub fn_diff {
### Process two files through the ignore lists, and then diff those files
### $_[0] is the first file, and $_[1] is the second file
	my $f_diff1 = $_[0];
	my $f_diff2 = $_[1];
	### Make the file names quote safe
	my $diff1_escape = fn_shell_escape_filename($f_diff1);
	my $diff2_escape = fn_shell_escape_filename($f_diff2);
	### With the file sizes we're looking at, most of the time the diff binary will be quicker than any tool Perl itself can provide
	my @v_diff = `diff $diff1_escape $diff2_escape 2> /dev/null`;
	@v_diff = fn_diff_check_lines( 2, undef, @v_diff );
	### Separate out just the file names from the diff
	my @v_deep_dirs;
	my $ref_diff;
	for my $_line (@v_diff) {
		my $v_first = substr( $_line, 0, 1 );
		if ( $v_first eq ">" || $v_first eq "<" ) {
			chomp($_line);
			my @v_line = split( m/'/, $_line );
			if ( $_line =~ m/^. Maximum depth reached at / ) {
				if ( $v_first eq ">" ) {
					pop(@v_line);
					shift(@v_line);
					my $v_file = join( "'", @v_line );
					push( @v_deep_dirs, fn_escape_filename($v_file) );
				}
				next;
			}
			my $v_line = pop(@v_line);
			### Remove up to the first single quote
			shift(@v_line);
			### Most files won't have single quotes in them, but just in case...
			my $v_file = join( "'", @v_line );
			if ( ! exists $ref_diff->{$v_file} ) {
				my $v_file_escape = fn_escape_filename($v_file);
				$ref_diff->{$v_file}->{'escape'} = $v_file_escape;
			}
			$ref_diff->{$v_file}->{$v_first}->{'line'} = $_line;
			@v_line = split( m/ -- /, $v_line );
			if ( scalar(@v_line) == 8 ) {
				if ( length($v_line[7]) == 32 ) {
					### If there's an md5sum, capture it
					$ref_diff->{$v_file}->{$v_first}->{'md5'} = pop(@v_line);
				} else {
					### I don't know what this is, so get rid of it
					pop(@v_line);
				}
			}
			my $v_ctime = pop(@v_line);
			my $v_mtime = pop(@v_line);
			$ref_diff->{$v_file}->{$v_first}->{'size'} = pop(@v_line);
			$ref_diff->{$v_file}->{$v_first}->{'group'} = pop(@v_line);
			$ref_diff->{$v_file}->{$v_first}->{'owner'} = pop(@v_line);
			$ref_diff->{$v_file}->{$v_first}->{'perms'} = pop(@v_line);
			if (! $b_partial_seconds) {
				$v_ctime =~ s/([0-9]{2}:[0-9]{2}:[0-9]{2})\.[0-9]+/$1/;
				$v_mtime =~ s/([0-9]{2}:[0-9]{2}:[0-9]{2})\.[0-9]+/$1/;
			}
			$ref_diff->{$v_file}->{$v_first}->{'ctime'} = $v_ctime;
			$ref_diff->{$v_file}->{$v_first}->{'mtime'} = $v_mtime;
		}
	}
	### Determine the changes, begin creating output
	if ( ! $ref_diff ) {
		if ($b_verbose) {
			if ( $v_format eq "text" ) {
				print $fh_output "No Differences\n";
			} else {
				print $fh_output "<b>No Differences</b>";
			}
		}
		return;
	}
	my @v_new;
	my @v_perms;
	my @v_size;
	my @v_stamps;
	my @v_removed;
	my $b_md5_change;
	$b_md5_all = 0;
	my $v_details = '';
	my $v_html_details = '';
	my $v_diff_details = '';
	my @v_files = sort {$a cmp $b} keys(%{ $ref_diff });
	my @v_files2;
	DIFF_FILE: for my $v_file (@v_files) {
		my $details = $ref_diff->{$v_file}->{'escape'} . "\n";
		my $html_details = "<b>" . $ref_diff->{$v_file}->{'escape'} . "</b>\n<br><table><tbody>";
		if ( ! exists $ref_diff->{$v_file}->{'<'} ) {
			### This file is new
			my $v_dir = substr( $ref_diff->{$v_file}->{'>'}->{'perms'}, 0, 1 );
			push( @v_new, $ref_diff->{$v_file}->{'escape'} );

			### Details Strings
			$v_diff_details .= $ref_diff->{$v_file}->{'>'}->{'line'} . "\n";
			$details .= "     Status:       New\n     M-time:       " . $ref_diff->{$v_file}->{'>'}->{'mtime'} . "\n     C-time:       " . $ref_diff->{$v_file}->{'>'}->{'ctime'} . "\n     File Size:    " . $ref_diff->{$v_file}->{'>'}->{'size'} . " bytes\n";
			my $html_details1 = '<tr><th>Status</th><th>M-time</th><th>C-time</th><th>File Size</th>';
			my $html_details2 = '<tr><td>New</td><td>' . $ref_diff->{$v_file}->{'>'}->{'mtime'} . '</td><td>' . $ref_diff->{$v_file}->{'>'}->{'ctime'} . '</td><td>' . $ref_diff->{$v_file}->{'>'}->{'size'}. ' bytes</td>';
			if ( exists $ref_diff->{$v_file}->{'>'}->{'md5'} ) {
				$details .= "     MD5 Sum:      " . $ref_diff->{$v_file}->{'>'}->{'md5'} . "\n";
				$html_details1 .= '<th>MD5 Sum</th>';
				$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'md5'} . '</td>';
			}
			$details .= "     Permissions:  " . $ref_diff->{$v_file}->{'>'}->{'perms'} . "\n     Owner:        " . $ref_diff->{$v_file}->{'>'}->{'owner'} . "\n     Group:        " . $ref_diff->{$v_file}->{'>'}->{'group'} . "\n";
			$html_details1 .= '<th>Permissions</th><th>Owner</th><th>Group</th></tr>' . "\n";
			$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'perms'} . '</td><td>' . $ref_diff->{$v_file}->{'>'}->{'owner'} . '</td><td>' . $ref_diff->{$v_file}->{'>'}->{'group'} . '</td></tr>' . "\n";

			### Check if there's anything else we need to do
			if ( $v_dir ne "d" ) {
				push( @v_files2, $v_file );
			}
			if ( $v_dir ne "d" && $b_backup ) {
				if ( exists $ref_diff->{$v_file}->{'>'}->{'md5'} ) {
					$b_md5_all = 1;
				}
				my $b_backup_success = fn_backup_file($v_file, $d_backup);
				$b_md5_all = 0;
				if ($b_backup_success) {
					$details .= "     Backed-up:    True\n";
					$html_details1 .= '<th>Backed-up</th>';
					$html_details2 .= '<td>True</td>';
				}
			}
			$html_details .= $html_details1 . "</tr>\n" . $html_details2 . "</tr>\n";
		} elsif ( ! exists $ref_diff->{$v_file}->{'>'} ) {
			### This file was removed
			push( @v_removed, $ref_diff->{$v_file}->{'escape'} );
			$v_diff_details .= $ref_diff->{$v_file}->{'<'}->{'line'} . "\n";
			$details .= "     Status:       Removed\n";
			$html_details .= '<tr><th>Status</th></tr>' . "\n";
			$html_details .= '<tr><td>Removed</td></tr>' . "\n";
		} else {
		### If the file wasn't new or removed, colect what data for it has changed
			my $details2 = '';
			my $html_details1 = '';
			my $html_details2 = '';
			my $html_details3 = '';
			my $html_details4 = '';
			my $b_owner;
			my $b_stamps;
			my $v_mention = '';
			my $b_list;
			my $v_dir = substr( $ref_diff->{$v_file}->{'>'}->{'perms'}, 0, 1 );
			if ( exists $ref_diff->{$v_file}->{'<'}->{'md5'} && exists $ref_diff->{$v_file}->{'>'}->{'md5'} ) {
				### Only compare md5sums if they exist for both
				if ( $ref_diff->{$v_file}->{'<'}->{'md5'} ne $ref_diff->{$v_file}->{'>'}->{'md5'} ) {
					push( @v_size, $ref_diff->{$v_file}->{'escape'} . $v_mention );
					$b_md5_change = 1;
					$v_mention = " (Also listed above)";
					$details2 .= "     MD5 Sum:      " . $ref_diff->{$v_file}->{'<'}->{'md5'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'md5'} . "\n";
					$html_details1 .= '<th>MD5 Sum</th>';
					$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'md5'} . '</td>';
					if ( $v_dir ne "d" && ! $b_list ) {
						push( @v_files2, $v_file );
						$b_list = 1;
					}
				}
			}
			if ( $ref_diff->{$v_file}->{'<'}->{'size'} ne $ref_diff->{$v_file}->{'>'}->{'size'} ) {
				push( @v_size, $ref_diff->{$v_file}->{'escape'} . $v_mention );
				$v_mention = " (Also listed above)";
				$details2 .= "     File Size:    " . $ref_diff->{$v_file}->{'<'}->{'size'} . " bytes -> " . $ref_diff->{$v_file}->{'>'}->{'size'} . " bytes\n";
				$html_details1 .= '<th>File Size</th>';
				$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'size'} . ' bytes</td>';
				if ( $v_dir ne "d" && ! $b_list ) {
					push( @v_files2, $v_file );
					$b_list = 1;
				}
			}
			if ( $ref_diff->{$v_file}->{'<'}->{'perms'} ne $ref_diff->{$v_file}->{'>'}->{'perms'} ) {
				$b_owner = 1;
				push( @v_perms, $ref_diff->{$v_file}->{'escape'} . $v_mention );
				$v_mention = " (Also listed above)";
				$details2 .= "     Permissions:  " . $ref_diff->{$v_file}->{'<'}->{'perms'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'perms'} . "\n";
				$html_details1 .= '<th>Permissions</th>';
				$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'perms'} . '</td>';
			}
			if ( $ref_diff->{$v_file}->{'<'}->{'owner'} ne $ref_diff->{$v_file}->{'>'}->{'owner'} ) {
				if (! $b_owner) {
					$b_owner = 1;
					push( @v_perms, $ref_diff->{$v_file}->{'escape'} . $v_mention );
					$v_mention = " (Also listed above)";
				}
				$details2 .= "     Owner:        " . $ref_diff->{$v_file}->{'<'}->{'owner'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'owner'} . "\n";
				$html_details1 .= '<th>Owner</th>';
				$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'owner'} . '</td>';
			}
			if ( $ref_diff->{$v_file}->{'<'}->{'group'} ne $ref_diff->{$v_file}->{'>'}->{'group'} ) {
				if (! $b_owner) {
					push( @v_perms, $ref_diff->{$v_file}->{'escape'} . $v_mention );
					$v_mention = " (Also listed above)";
				}
				$details2 .= "     Group:        " . $ref_diff->{$v_file}->{'<'}->{'group'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'group'} . "\n";
				$html_details1 .= '<th>Group</th>';
				$html_details2 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'group'} . '</td>';
			}
			if ( $v_mention ) {
				### If we've seen a difference so far, do nothing so we can move forward
			} elsif ( substr( $ref_diff->{$v_file}->{'<'}->{'perms'}, 0, 1 ) eq "d" || $v_dir eq "d" ) {
				### If it dasn't been mentioned, and it's a directory, move forward
				next DIFF_FILE;
			} else {
				for my $_string (@v_time_minus){
					if ( $v_file eq $_string ) {
						### if this file is listed for us to ignore stamps, go on to the next file
						next DIFF_FILE;
					}
				}
			}
			if ( $ref_diff->{$v_file}->{'<'}->{'mtime'} ne $ref_diff->{$v_file}->{'>'}->{'mtime'} ) {
				$b_stamps = 1;
				push( @v_stamps, $ref_diff->{$v_file}->{'escape'} . $v_mention );
				$v_mention = " (Also listed above)";
				$details .= "     M-time:       " . $ref_diff->{$v_file}->{'<'}->{'mtime'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'mtime'} . "\n";
				$html_details3 .= '<th>M-time</th>';
				$html_details4 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'mtime'} . '</td>';
				if ( $v_dir ne "d" && ! $b_list ) {
					push( @v_files2, $v_file );
					$b_list = 1;
				}
			}
			if ( $b_diff_ctime && $ref_diff->{$v_file}->{'<'}->{'ctime'} ne $ref_diff->{$v_file}->{'>'}->{'ctime'} ) {
				if (! $b_stamps) {
					push( @v_stamps, $ref_diff->{$v_file}->{'escape'} . $v_mention );
					$v_mention = " (Also listed above)";
				}
				$details .= "     C-time:       " . $ref_diff->{$v_file}->{'<'}->{'ctime'} . " -> " . $ref_diff->{$v_file}->{'>'}->{'ctime'} . "\n";
				$html_details3 .= '<th>C-time</th>';
				$html_details4 .= '<td>' . $ref_diff->{$v_file}->{'>'}->{'ctime'} . '</td>';
				if ( $v_dir ne "d" && ! $b_list ) {
					push( @v_files2, $v_file );
					$b_list = 1;
				}
			}
			if ( ! $v_mention ) {
				next DIFF_FILE;
			}
			### Attempt to backup the file
			if ( $v_dir ne "d" && $b_backup ) {
				if ( exists $ref_diff->{$v_file}->{'>'}->{'md5'} ) {
					$b_md5_all = 1;
				}
				my $b_backup_success = fn_backup_file($v_file, $d_backup);
				$b_md5_all = 0;
				if ($b_backup_success) {
					$details2 .= "     Backed-up:    True\n";
					$html_details1 .= '<th>Backed-up</th>';
					$html_details2 .= '<td>True</td>';
				}
			}
			$v_diff_details .= $ref_diff->{$v_file}->{'<'}->{'line'} . "\n" . $ref_diff->{$v_file}->{'>'}->{'line'} . "\n";
			$details .= $details2;
			$html_details .= '<tr>' . $html_details3 . $html_details1 . "</tr>\n<tr>" . $html_details4 . $html_details2 . "</tr>\n";
		}
		$v_details .= $details . "\n";
		$v_html_details .= $html_details . '</tbody></table><br>' . "\n";
	}
	if ( ! @v_new && ! @v_removed && ! @v_size && ! @v_perms && ! @v_stamps ) {
		if ($b_verbose) {
			if ( $v_format eq "text" ) {
				print $fh_output "No Differences\n";
			} else {
				print $fh_output "<b>No Differences</b>";
			}
		}
		return;
	}
	my $v_details2 = '';
	my $v_html_details2 = '';
	if (@v_new) {
		$v_details2 .= "FILES THAT WERE NOT PRESENT PREVIOUSLY:\n";
		$v_html_details2 .= '<h2>Files that were not Present Previously:</h2>' . "\n";
		for my $_file (@v_new) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	if (@v_removed) {
		$v_details2 .= "FILES THAT WERE REMOVED:\n";
		$v_html_details2 .= '<h2>Files that were Removed:</h2>' . "\n";
		for my $_file (@v_removed) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	if (@v_size) {
		if ($b_md5_change) {
			$v_details2 .= "FILES WITH A DIFFERENT SIZE OR MD5 SUM:\n";
			$v_html_details2 .= '<h2>Files with a Different Size or MD5 Sum:</h2>' . "\n";
		} else {
			$v_details2 .= "FILES THAT CHANGED IN SIZE:\n";
			$v_html_details2 .= '<h2>Files that Changed in Size:</h2>' . "\n";
		}
		for my $_file (@v_size) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	if (@v_perms) {
		$v_details2 .= "FILES WITH CHANGES TO PERMISSIONS OR OWNER:\n";
		$v_html_details2 .= '<h2>Files with Changes to their Permissions or Owner:</h2>' . "\n";
		for my $_file (@v_perms) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	if (@v_stamps) {
		$v_details2 .= "FILES WITH CHANGES TO M-TIME OR C-TIME:\n";
		$v_html_details2 .= '<h2>Files with Changes to ther M-time or C-time:</h2>' . "\n";
		for my $_file (@v_stamps) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	if (@v_deep_dirs) {
		$v_details2 .= "DIRECTORIES TOO DEEP TO PROCESS:\n";
		$v_html_details2 .= '<h2>Directories too Deep to Process:</h2>' . "\n";
		for my $_file (@v_deep_dirs) {
			$v_details2 .= "   " . $_file . "\n";
			$v_html_details2 .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $_file . "<br>\n";
		}
		$v_details2 .= "\n";
		$v_html_details2 .= "<br>\n";
	}
	$v_details = $v_details2 . "\nSPECIFICS FOR EACH FILE:\n\n" . $v_details;
	$v_html_details = $v_html_details2 . "<br><h2>Specifics for each File:</h2>\n" . $v_html_details;
	##### @v_files2 contains a list of everything new or changed in case I want to run a malware scan against them.
	if ( $v_format eq "html" ) {
		print $fh_output $v_html_details;
	} elsif ( $v_format eq "diff" ) {
		print $fh_output $v_diff_details;
	} else {
		print $fh_output $v_details;
	}
}

sub fn_diff_lines {
### Given a line from a Stat Watch report, process it.
### $_[0] is the line; $_[1] is the regular expression indicating multi-line file names; $_[2] and $_[3] are the first and second timestamps
### $_[4] is the directory that we're currently processing; $_[5] is the error message to give if things are wrong
	my ($v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing, $v_prune, $v_error) = @_;
	chomp($v_line);
	my $v_start = substr($v_line, 0, $v_prune);
	$v_line = substr($v_line, $v_prune);
	if ( $v_line =~ m/^Processing:/ ) {
		### Each time we see a processing line, we have to re-do the ignore strings to make sure that we're not ignoring something we shouldn't
		$v_processing = (split( m/'/, $v_line, 2 ))[1];
		### Trade timestamps
		$v_timestamp2 = $v_timestamp1;
		$v_timestamp1 = $v_processing;
		$v_timestamp1 =~ s/^.*\s([0-9]+)$/$1/;
		### create the regex for the multi-line
		$re_multiline = qr/_mlfn_(\Q$v_timestamp1\E|\Q$v_timestamp2\E)/;
		if ( $v_timestamp2 eq '' ) {
			$re_multiline = qr/_mlfn_\Q$v_timestamp1\E/;
		}
		$v_processing =~ s/' - [0-9]+$//;
		### Check to see if anything needs to be ignored
		fn_check_strings( $v_processing );
		$v_line = 0;
	} elsif ( substr( $v_line, 0, 2 ) eq "'/" || $v_line =~ m/^Maximum depth reached at '/ ) {
		### If we've reached a normal line before we reached a processing line, there's a problem
		if ( ! $v_processing ) {
			print STDERR $v_error;
			exit 1;
		}
		my @v_line = split( m/'/, $v_line );
		$v_line = pop(@v_line);
		### Special capturing steps if it's a max depth line
		if ( $v_line[0] eq 'Maximum depth reached at ' ) {
			$v_start .= shift(@v_line);
		} else {
			### regular lines would have begun with a single quote, so the split means that there's an empty string at the beginning of the array. Get rid of it.
			shift(@v_line);
		}
		my $v_file = join( "'", @v_line );
		if ( $v_file =~ m/$re_multiline/ ) {
			$v_file =~ s/$re_multiline/\n/g;
		}
		### Check to see if there's any reason for the file to be excluded. If not, output it
		if ( fn_check_file($v_file) ) {
			$v_line = $v_start . "'" . $v_file . "'" . $v_line;
		} else {
			$v_line = 0;
		}
	}
	return( $v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing );
}

sub fn_diff_check_lines {
### Check lines in a Stat Watch report to see if the file described matches the ignore lists. If not, output them to a file
### Prune timestamps from directories so they don't cause false positives
### $_[0] is the number of characters to ignore from the beginning of each line
### $_[1] is 1 if we're reading from a file, and 0 if we're reading from an array
### $_[2] is the filename or the array
	my $v_prune = ( shift(@_) || 0 );
	my $b_file = ( shift(@_) || 0 );
	my @v_lines_out;
	my $v_processing;
	my $v_timestamp1 = '';
	my $v_timestamp2 = '';
	my $re_multiline;
	my $v_error = "Input does not appear to be from a Stat Watch file\n";
	if ($b_file) {
	### If we're reading from a file
		my $f_read = shift(@_);
		my $f_read_escape = fn_escape_filename($f_read);
		$v_error = "File " . $f_read_escape . " does not appear to be a Stat Watch file\n";
		if ( open( my $fh_read, "<", $f_read ) ) {
			while (<$fh_read>) {
				my $v_line = $_;
				($v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing) = fn_diff_lines($v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing, $v_prune, $v_error);
				if ($v_line) {
					push( @v_lines_out, $v_line ) ;
				}
			}
		}
	} else {
	### Otherwise we've been given an array
		my @v_lines_in = @_;
		for my $v_line (@v_lines_in) {
			($v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing) = fn_diff_lines($v_line, $re_multiline, $v_timestamp1, $v_timestamp2, $v_processing, $v_prune, $v_error);
			if ($v_line) {
				push( @v_lines_out, $v_line ) ;
			}
		}
	}
	return @v_lines_out;
}

#======================#
#== Backing up Files ==#
#======================#

sub fn_backup_initial {
### Given a Stat Watch report, backup the files within that match the "BackupR" and "Backup+" control strings
### $_[0] is the report
	my $v_file = $_[0];
	$b_md5_all = 0;
	my @v_lines = fn_diff_check_lines(undef, 1, $v_file);
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
				$b_md5_all = 1;
			}
		}
		fn_backup_file($v_file, $d_backup);
		$b_md5_all = 0;
	}
}

sub fn_check_retention {
### Given the name of a backed-up file, check to ensure that there aren't old copies that exceed the retention limits
### $_[0] is the full path to that file in the backup directory, but with the trailing underscore and timestamp removed
	my $v_file = $_[0];
	my @v_dirs = split( m/\//, $v_file );
	my $v_name = pop(@v_dirs);
	my $v_dir = join( '/', @v_dirs );
	my @v_files = fn_list_backups($v_name, $v_dir);
	### Sort the matching files in reverse, then skip over the retention count. delete anything after that point that's too old
	@v_files = sort {$b cmp $a} @v_files;
	my $v_count = $v_retention_max_copies + 1;
	while ( defined $v_files[$v_count] ) {
		my $v_file = $v_dir . "/" . $v_files[$v_count];
		my $v_stamp = (split( m/_/, $v_files[$v_count] ))[-1];
		if ( (time() - $v_stamp) > (86400 * $v_retention_min_days) ) {
			my $v_file_escape = fn_escape_filename($v_file);
			fn_log("Removing backed-up file " . $v_file_escape . "\n");
			unlink( $v_file );
			if ( -f $v_file . "_comment" ) {
				unlink( $v_file . "_comment" );
			}
		}
		$v_count++;
	}
}

sub fn_prune_backups {
### This is the main function that's run with the "--prune" option
### $_[0] is the backup directory
	my $v_dir = $_[0];
	if ($b_verbose) {
		my $v_dir_escape = fn_escape_filename($v_dir);
		print STDERR "Directory: " . $v_dir_escape . "\n";
	}
	if ( -e $v_dir && -d $v_dir ) {
		### Open the directory and get a file list
		if ( opendir my $fh_dir, $v_dir ) {
			my @files = readdir $fh_dir;
			closedir $fh_dir;
			my @dirs;
			for my $_file (@files) {
				if ( -d $_file && ! -l $_file && $_file ne "." && $_file ne ".." ) {
					push( @dirs, $_file );
				}
				$_file =~ s/_[0-9]+$//;
			}
			@files = fn_uniq(@files);
			for my $_file (@files) {
				if ( $_file ne "." && $_file ne ".." ) {
					$_file = $v_dir . "/" . $_file;
					fn_check_retention($_file);
				}
			}
			for my $_dir (@dirs) {
			### For each of the directories we found, go through RECURSIVELY!
				fn_prune_backups($_dir);
			}
		}
	}
}

sub fn_backup_file {
### Check to make sure that a file matches the desired regex, then make a copy of the file
### $_[0] is the file we're copying, $_[1] is the backup directory
	my $v_file = $_[0];
	my $d_backup = $d_backup;
	if ( $_[1] ) {
		$d_backup = $_[1];
	}
	my $b_continue;
	if ( ! -f $v_file && ! -l $v_file ) {
		return;
	}
	for my $_string (@v_backup_plus) {
		if ( $v_file eq $_string ) {
			$b_continue = 1;
			last;
		}
	}
	if ( ! $b_continue ) {
		for my $_string (@v_backupr) {
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
		for my $_dir (@v_dirs) {
			$d_backup .= "/" . $_dir;
			if ( ! -d $d_backup ) {
				mkdir( $d_backup );
				chmod( 0700, $d_backup );
			}
		}
		my $v_file_escape = fn_escape_filename($v_file);
		if ( -d $d_backup ) {
			$b_continue = fn_compare_backup($v_file, $d_backup);
			if ( $b_continue ) {
				### No need to back it up, because it already matches
				return $b_continue;
			}
			$d_backup .= "/" . $v_name . "_" . time();
			### When ever running a command with backticks, we need to make sure arguments we're passing to it are quote safe:
			system( "cp", "-a", $v_file, $d_backup );
			### Test if the files was successfully copied
			if ( -f $d_backup || -l $d_backup ) {
				if ($b_verbose) {
					my $d_backup_escape = fn_escape_filename($d_backup);
					print STDERR $v_file_escape . " -> " . $d_backup_escape . "\n";
				}
				fn_log("Backed up file " . $v_file_escape . "\n");
				if ($b_retention) {
					fn_check_retention( $d_backup .= "/" . $v_name );
				}
				return $d_backup;
			}
		}
		fn_log("Failed to backup file " . $v_file_escape . "\n");
		if ($b_verbose) {
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

sub fn_stat_line {
### Given the name of a file, get stats for that file
	my $v_file = $_[0];
	my $v_line;
	if ( -l $v_file ) {
		$v_line = join( ' -- ', (lstat($v_file))[2,4,5,7,9] );
	} else {
		$v_line = join( ' -- ', (stat($v_file))[2,4,5,7,9] );
	}
	if ($b_md5_all) {
	### This should only be the case if the file was listed with an md5sum
		$v_line .= fn_check_md5($v_file);
	}
	return $v_line;
}

sub fn_compare_backup {
### Compare an existing backup to the files it was taken from
### This will compare user, group, permissions, size, and mtime of the two files
### If they are the same, it will return true
### $_[0] is the file in-place, $_[1] is the directory that it's in
	my $v_file = $_[0];
	my $v_dir = $_[1];
	my @v_dirs = split( m/\//, $v_file );
	my $v_name = pop(@v_dirs);
	my @v_files = fn_list_backups($v_name, $v_dir);
	if (@v_files) {
		@v_files = sort {$b cmp $a} @v_files;
		### Since I don't anticipate this needing to be human readable, there's no reason to use the stat binary
		my $v_file2 = $v_dir . "/" . $v_files[0];
		my $v_line1 = fn_stat_line($v_file);
		my $v_line2 = fn_stat_line($v_file2);
		if ( $v_line1 eq $v_line2 ) {
			return $v_file2;
		}
	}
	return 0;
}

sub fn_list_file {
### Given a file name, list the backups that are available for it
### $_[0] is the full path for the file
	my $v_file = $_[0];
	my @v_backup_dirs;
	if ($d_backup) {
		@v_backup_dirs = ($d_backup);
	}
	{
	### Find all of the backup directories that have been used
		my $v_dir = $d_working;
		if ( ! -d $v_dir ) {
			mkdir( $v_dir );
		}
		### Open the list and read from it
		if ( -f $v_dir . "/backup_locations" ) {
			if ( open( my $fh_read, "<", $v_dir . "/backup_locations" ) ) {
				while (<$fh_read>) {
					my $_line = $_;
					chomp($_line);
					if ( ! $d_backup || $_line ne $d_backup ) {
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
	my @v_files;
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
			$_file = $d_backup . "/" . $_file;
		}
		push( @v_files, @v_files2 );
	}
	### Output the details
	my $v_file_escape = fn_escape_filename($v_file);
	print "\nAvailable Backups for " . $v_file_escape . ":\n";
	if (@v_files) {
		@v_files = sort {$a cmp $b} @v_files;
		for my $_file (@v_files) {
			my $v_stamp = (split( m/_/, $_file ))[-1];
			$v_stamp = strftime( '%Y-%m-%d %T %z', localtime($v_stamp) );
			my $v_size;
			if ( -l $_file ) {
				$v_size = (lstat($_file))[7];
			} else {
				$v_size = (stat($_file))[7];
			}
			my $_file_escape = fn_escape_filename($_file);
			print "  " . $_file_escape . " -- Timestamp: " . $v_stamp . " -- " . $v_size . " bytes\n";
			if ( -f $_file . "_comment" ) {
				fn_print_files( $_file . "_comment" );
			}
		}
	} else {
		print "There are no backups of this file\n"
	}
}
#=============================#
#== Processing the job file ==#
#=============================#

sub fn_get_include {
### Read the job file and extract data from it
### $_[0] is the file in question.
	my $f_ignore = $_[0];
	if ( ! -r $f_ignore ) {
		my $f_ignore_escape = fn_escape_filename($f_ignore);
		print STDERR "Cannot read file " . $f_ignore_escape . "\n";
	}
	### Make sure we don't read a file twice
	for my $_include (@v_includes) {
		if ( $f_ignore eq $_include ) {
			return;
		}
	}
	push( @v_includes, $f_ignore );
	### Read the job file
	if ( open( my $fh_read, "<", $f_ignore ) ) {
		while (<$fh_read>) {
			my $_line = $_;
			chomp($_line);
			### Remove any space at the start or end of the line
			$_line =~ s/(^\s*|\s*$)//g;
			if ( $_line =~ m/^R\s*[^\s]/ ) {
			### Regex for files to ignore
				$_line =~ s/^R\s*//;
				push( @v_rignore, $_line );
			} elsif ( $_line =~ m/^BackupR\s*[^\s]/ ) {
			### Regex for files to back up
				$_line =~ s/^BackupR\s*//;
				push( @v_backupr, qr/$_line/ );
			} elsif ( $_line =~ m/^MD5R\s*[^\s]/ ) {
			### Regex for files to check md5sums in addition to stats
				$_line =~ s/^MD5R\s*//;
				push( @v_md5r, qr/$_line/ );
			} else {
				### There are no instances where double slashes will be necessary in file names. Get rid of them.
				$_line =~ s/\/\/+/\//g;
				### We don't need trailing slashes either
				$_line =~ s/\/$//;
				if ( substr( $_line,0,1 ) eq "/" ) {
				### Ignore files with this exact name
					push( @v_ignore, $_line );
				} elsif ( $_line =~ m/^\*\s*\// ) {
				### Ignore all files whose full path starts with this string
					$_line =~ s/^\*\s*//;
					push( @v_star_ignore, $_line );
				} elsif ( $_line =~ m/^Include\s*\// ) {
				### Process these files as additional job files
					$_line =~ s/^Include\s*//;
					fn_get_include( $_line );
				} elsif ( $_line =~ m/^I\s*\// ) {
				### Also report on these files / directories
					$_line =~ s/^I\s*//;
					push( @v_dirs, $_line );
				} elsif ( $_line =~ m/^BackupD\s*\// ) {
				### Set a directory to back up to
					$_line =~ s/^BackupD\s*//;
					$d_backup = $_line;
				} elsif ( $_line =~ m/^Backup\+\s*\// ) {
				### Specify a file that should be backed up if there are changes
					$_line =~ s/^Backup\+\s*//;
					push(@v_backup_plus, $_line);
				} elsif ( $_line =~ m/^MD5\s*\// ) {
				### Specify a file that we want to capture the md5 sum of
					$_line =~ s/^MD5\s*//;
					push(@v_md5, $_line);
				} elsif ( $_line eq "MD5" ) {
				### If we just want to md5sum everything...
					$b_md5_all = 1;
				} elsif ( $_line =~ m/^BackupMD\s*[0-9]/ ) {
				### The minimum number of days a backup is kept
					$_line =~ s/^BackupMD\s*//;
					$_line =~ s/[^0-9].*$//;
					$v_retention_min_days = $_line;
				} elsif ( $_line =~ m/^BackupMC\s*[0-9]/ ) {
				### The maximum number of backups to be kept
					$_line =~ s/^BackupMC\s*//;
					$_line =~ s/[^0-9].*$//;
					$v_retention_max_copies = $_line;
				} elsif ( $_line =~ m/^Max-depth\s*[0-9]/ ) {
				### The maximum depth of directories that we will recurse into
					$_line =~ s/^Max-depth\s*//;
					$_line =~ s/[^0-9].*$//;
					$v_max_depth = $_line;
				} elsif ( $_line =~ m/^Log\s*\// ) {
				### Where to log actions
					$_line =~ s/^Log\s*//;
					$f_log = $_line;
				} elsif ( $_line =~ m/^Time-\s*\// ) {
				### Specify a file that we should be unconcerned about changes to the timestamps
					$_line =~ s/^Time-\s*//;
					push(@v_time_minus, $_line);
				}
			}
		}
		close( $fh_read );
	}
}

sub fn_document_backup {
### Document the backup locations we've seen so that we can check all of them when necessary
	if ( $d_backup ) {
	### If the job file listed a backup directory, add that to the list of backup directories
		my @v_backup_dirs;
		### Open the list and read from it
		if ( -f $d_working . "/backup_locations" ) {
			if ( open( my $fh_read, "<", $d_working . "/backup_locations" ) ) {
				while (<$fh_read>) {
					my $_line = $_;
					chomp($_line);
					if ( $_line eq $d_backup ) {
						### If it's already there, we don't need to add it
						return;
					}
					push( @v_backup_dirs, $_line );
				}
				close($fh_read);
			}
		}
		### If we've gotten this far, it wasn't in the list. Add it
		push( @v_backup_dirs, $d_backup );
		if ( open( my $fh_write, ">", $d_working . "/backup_locations" ) ) {
			for my $_line (@v_backup_dirs) {
				print $fh_write $_line . "\n";
			}
			close($fh_write);
		}
	}
}

sub fn_check_strings {
### Compare the current directory to ignore strings. Only take ones that would not match the current directory
### $_[0] is the directory we're comparing against
	my $v_dir = $_[0];
	@v_temp_ignore = ();
	@v_temp_rignore = ();
	@v_temp_star_ignore = ();
	for my $_string (@v_ignore){
		if ( $v_dir ne $_string ) {
			push( @v_temp_ignore, $_string );
		}
	}
	for my $_string (@v_rignore) {
		my $v_string = qr/$_string/;
		if ( ($v_dir . "/" ) !~ m/$v_string/ ) {
			push( @v_temp_rignore, $v_string );
		}
	}
	for my $_string (@v_star_ignore){
		my $v_string = qr/^\Q$_string\E/;
		if ( $v_dir !~ m/$v_string/ ) {
			push( @v_temp_star_ignore, $v_string );
		}
	}
}

sub fn_sort_prep {
### Sort the relevant arrays, then open the output file
	@v_dirs = sort {$a cmp $b} @v_dirs;
	@v_ignore = sort {$a cmp $b} @v_ignore;
	@v_rignore = sort {$a cmp $b} @v_rignore;
	@v_star_ignore = sort {$a cmp $b} @v_star_ignore;
	### Open the file for output
	if ( defined $f_output && open( $fh_output, ">", $f_output ) ) {
		return 1;
	} elsif ( defined $f_output ) {
		my $f_output_escape = fn_escape_filename($f_output);
		print STDERR "Cannot open file " . $f_output_escape . " for writing\n";
		exit 1;
	} else {
		$fh_output = \*STDOUT;
		return 0;
	}
}

#=============#
#== Logging ==#
#=============#

sub fn_log {
### Given a message, check if there's a place to log it to, then log it.
### $_[0] is the message
	my $v_message = $_[0];
	if (! $f_log) {
		return;
	}
	if ( $f_log && ! $fh_log ) {
		if ( ! (open( $fh_log, ">>", $f_log )) ) {
			undef $f_log;
			return;
		}
	}
	if ($v_message) {
		my $v_stamp = strftime( '%Y-%m-%d %T %z', localtime);
		chomp($v_message);
		print $fh_log $v_stamp . " - " . $v_message . "\n";
	}
}

#========================#
#== Helper Subroutines ==#
#========================#

sub fn_date_files {
### Given two file names, return those file names in order of mtime, oldest to newest
	my $v_file1 = $_[0];
	my $v_file2 = $_[1];
	my $mtime1 = (stat($v_file1))[9];
	my $mtime2 = (stat($v_file2))[9];
	if ( $mtime1 < $mtime2 ) {
		return( $v_file1, $v_file2 );
	} elsif ( $mtime1 > $mtime2 ) {
		return( $v_file2, $v_file1 );
	}
	### If the mtimes are equal, return in the order given
	return( $v_file1, $v_file2 );
}


sub fn_test_file {
### Given a file name, test against it. Does it exist? What's it's file type?
### $_[0] is the path to the file; $_[1] is whether or not it needs to exist; $_[2] is whether it needs to test as a certain type.
	my $v_file = $_[0];
	my $b_exist = ( $_[1] || 0 );
	my $v_type = ( $_[2] || 0 );
	if ( ! -p $v_file ) {
		$v_file = ( abs_path( $v_file ) || $v_file );
	}
	if ( $b_exist ) {
		if ( ! -e $v_file ) {
			return 0;
		}
	}
	if ( $v_type ) {
		if ( $v_type eq "f" ) {
			if ( -p $v_file ) {
			### Sometimes files are pipes.
				return $v_file;
			} elsif ( ! -f $v_file && -e $v_file ) {
				return 0;
			}
		} elsif ( $v_type eq "d" ) {
			if ( ! -d $v_file && -e $v_file ) {
				return 0;
			}
		}
	}
	return $v_file;
}

sub fn_uniq {
### Given an array, reduce the array to unique elements
### @_ is the array
	my @v_array = @_;
	my %v_hash;
	for my $v_item (@v_array) {
		$v_hash{$v_item} = 1;
	}
	my @v_array2;
	for my $v_item (keys(%v_hash)) {
		push( @v_array2, $v_item );
	}
	return @v_array2;
}

sub fn_report_unknown {
### Given an array of arguments that didn't match known arguments, report those arguments as unknown
	print STDERR "The following arguments were not recognized:\n";
	for my $_arg (@_) {
		print STDERR "  '" . $_arg . "'\n";
	}
	print STDERR "\n";
	sleep( 2 );
}

sub fn_escape_filename {
### Given a file name that might have unprintable characters, appropriately escape and quote everything
	my $v_file = $_[0];
	if ( $v_file =~ m/'/ ) {
		### replace all single quotes with a single quote, a backslash, and then two single quotes
		$v_file =~ s/'/'\\''/g;
	}
	if ( $v_file =~ m/[\001-\037\x7F]/ ) {
		### For blocks of unprintable characters, place "'$'" at the start, and "'" at the end
		$v_file =~ s/([\x01-\x1F\x7F]+)/'\$'$1''/g;
		### Replace unprintable characters with their hex value or special character
		$v_file =~ s/\001/\\001/g;
		$v_file =~ s/\002/\\002/g;
		$v_file =~ s/\003/\\003/g;
		$v_file =~ s/\004/\\004/g;
		$v_file =~ s/\005/\\005/g;
		$v_file =~ s/\006/\\006/g;
		$v_file =~ s/\007/\\a/g;
		$v_file =~ s/\010/\\b/g;
		$v_file =~ s/\011/\\t/g;
		$v_file =~ s/\012/\\n/g;
		$v_file =~ s/\013/\\v/g;
		$v_file =~ s/\014/\\f/g;
		$v_file =~ s/\015/\\r/g;
		$v_file =~ s/\016/\\016/g;
		$v_file =~ s/\017/\\017/g;
		$v_file =~ s/\020/\\020/g;
		$v_file =~ s/\021/\\021/g;
		$v_file =~ s/\022/\\022/g;
		$v_file =~ s/\023/\\023/g;
		$v_file =~ s/\024/\\024/g;
		$v_file =~ s/\025/\\025/g;
		$v_file =~ s/\026/\\026/g;
		$v_file =~ s/\027/\\027/g;
		$v_file =~ s/\030/\\030/g;
		$v_file =~ s/\031/\\031/g;
		$v_file =~ s/\032/\\032/g;
		$v_file =~ s/\033/\\033/g;
		$v_file =~ s/\034/\\034/g;
		$v_file =~ s/\035/\\035/g;
		$v_file =~ s/\036/\\036/g;
		$v_file =~ s/\037/\\037/g;
		$v_file =~ s/\x7F/\\177/g;
	}
	### Add a quote at the start of the file name
	$v_file = "'" . $v_file . "'";
	return $v_file;
}

sub fn_shell_escape_filename {
	my $v_file = $_[0];
	$v_file =~ s/'/'\\''/g;
	$v_file = "'" . $v_file . "'";
	return $v_file;
}

sub fn_unescape_filename {
	my $v_file = $_[0];
	while ( $v_file =~ m/'\$'[\\0-7abtnvfr]+''/ ) {
	### for each block of escaped hex characters
		### separate out the block, and use a null character as a place holder
		my $v_file2 = substr( $&, 3, -2 );
		$v_file = $` . "\000" . $';
		### Replace all of the escaped characters
		$v_file2 =~ s/\\001/\001/g;
		$v_file2 =~ s/\\002/\002/g;
		$v_file2 =~ s/\\003/\003/g;
		$v_file2 =~ s/\\004/\004/g;
		$v_file2 =~ s/\\005/\005/g;
		$v_file2 =~ s/\\006/\006/g;
		$v_file2 =~ s/\\a/\007/g;
		$v_file2 =~ s/\\b/\010/g;
		$v_file2 =~ s/\\t/\011/g;
		$v_file2 =~ s/\\n/\012/g;
		$v_file2 =~ s/\\v/\013/g;
		$v_file2 =~ s/\\f/\014/g;
		$v_file2 =~ s/\\r/\015/g;
		$v_file2 =~ s/\\016/\016/g;
		$v_file2 =~ s/\\017/\017/g;
		$v_file2 =~ s/\\020/\020/g;
		$v_file2 =~ s/\\021/\021/g;
		$v_file2 =~ s/\\022/\022/g;
		$v_file2 =~ s/\\023/\023/g;
		$v_file2 =~ s/\\024/\024/g;
		$v_file2 =~ s/\\025/\025/g;
		$v_file2 =~ s/\\026/\026/g;
		$v_file2 =~ s/\\027/\027/g;
		$v_file2 =~ s/\\030/\030/g;
		$v_file2 =~ s/\\031/\031/g;
		$v_file2 =~ s/\\032/\032/g;
		$v_file2 =~ s/\\033/\033/g;
		$v_file2 =~ s/\\034/\034/g;
		$v_file2 =~ s/\\035/\035/g;
		$v_file2 =~ s/\\036/\036/g;
		$v_file2 =~ s/\\037/\037/g;
		$v_file2 =~ s/\\177/\x7F/g;
		### Put the block of non-printable characters back in place
		$v_file =~ s/\000/$v_file2/;
	}
	if ( $v_file =~ m/'\\''/ ) {
		$v_file =~ s/'\\''/'/g;
	}
	### Remove the first and last character, because they're single quotes
	$v_file = substr( $v_file, 1, -1 );
	return $v_file;
}

sub fn_get_working {
### Given the full path to the program, return the name of an appropriate working directory
	my $v_program = $_[0];
	$v_program = ( readlink($v_program) || $v_program );
	$v_program = ( abs_path($v_program) || $v_program );
	my @v_working = split( m/\//, $v_program );
	my $v_name = pop( @v_working );
	$v_name =~ s/\.pl$//;
	my $d_program = join( '/', @v_working );
	my $d_working = $d_program . "/." . $v_name;
	if ( ! -d $d_working ) {
		mkdir( $d_working, 0755 );
	}
	return( $d_working, $d_program );
}

sub fn_mod_check {
### Given a list of perl modules, check if they're located somewhere within @INC
	my @module_list = @_;
	my $b_exit = 1;

	if ( $module_list[-1] eq "0" ) {
		$b_exit = pop(@module_list);
	}

	### Check for the modules. Compile a list of any that are not present.
	my @missing_modules;
	MODULES: for my $module ( @module_list ) {
		my $module2 = $module;
		$module2 =~ s/::/\//g;
		for my $dir ( @INC ) {
			if ( -f $dir . "/" . $module2 . ".pm" ) {
				next MODULES;
			}
		}
		push( @missing_modules, $module );
	}

	### If any of the modules are missing, let the user know and exit
	if ( @missing_modules && $b_exit ) {
		print "You will need to install the following Perl modules:\n\n";
		for ( @missing_modules ) {
			print $_, "\n";
		}
		print "\n";
		print "In order to do so, run the following command:\n\n";
		print "cpan -i @missing_modules\n\n";
		exit;
	} elsif ( @missing_modules ) {
		return 0;
	}
	return 1;
}

sub fn_test_for_bin {
### This tests if there's a binary command available within $PATH and returns the full path of the first such binary found.
### $_[0] is the name of the binary that we're checking for.
	if( exists $ENV{PATH} && defined $ENV{PATH} ) {
		my @v_paths = split( m/:/, $ENV{PATH} );
		for ( @v_paths ) {
			if ( -f ( $_ . "/" . $_[0] ) && -x ( $_ . "/" . $_[0] ) ) {
				return ( $_ . "/" . $_[0] );
			}
		}
	}
	return;
}

sub fn_bin_check {
### Given an array of necessary external programs, ler the end user know if any are missing
	my @ext_progs = @_;

	### Check all of the programs and make a list of the missing ones.
	my @missing_progs;
	for my $prog ( @ext_progs ) {
		if ( ! fn_test_for_bin( $prog ) ) {
			push( @missing_progs, $prog );
		}
	}

	### Warn the user if any are missing.
	if ( @missing_progs ) {
		print "This script relies on the following external programs that do not appear to be installed:\n";
		for ( @missing_progs ) {
			print $_, "\n";
		}
		print "\n";
		exit 1;
	}
}

#==================================#
#== Parse command line arguments ==#
#==================================#

### Find the working directory, in case it's needed
($d_working,$d_program) = fn_get_working($v_program);

### Process all of the universal arguments first
my @args;
while ( defined $ARGV[0] ) {
	my $v_arg = shift( @ARGV );
	my $v_file;
	if ( $v_arg =~ m/^-[a-zA-Z0-9][a-zA-Z0-9]+$/ ) {
	### If there's a string of single character arguments, break them up and process them separately
		my @v_args = split( m//, substr($v_arg,1) );
		for my $a (@v_args) {
			unshift( @ARGV, "-" . $a );
		}
	} elsif ( $v_arg =~ m/^-[a-zA-Z0-9][a-zA-Z0-9]+=.*$/ ) {
	### If it's single character arguments, and then there's an equals sign followed by more data
	### ...this isn't posix compliant, but let's split it up anyway
		my @v_args = split( m/=/, $v_arg, 2 );
		unshift( @ARGV, pop(@v_args) );
		unshift( @ARGV, pop(@v_args) );
	} elsif ( $v_arg =~ m/^--.*=/ ) {
	### If it's a full-style argument with an euals sign, split at the equals sign and make it two arguments
		my @v_args = split( m/=/, $v_arg, 2 );
		for my $a (@v_args) {
			unshift( @ARGV, $a );
		}
	} elsif ( $v_arg eq "--ignore" ) {
		if ( defined $ARGV[0] ) {
			$v_file = fn_test_file(shift( @ARGV ), 1);
		}
		if ( $v_file ) {
			push( @v_ignore, $v_file );
		} else {
			print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
		}
	} elsif ( $v_arg eq "-i" || $v_arg eq "--include" ) {
		if ( defined $ARGV[0] ) {
			$v_file = fn_test_file(shift( @ARGV ), 1);
		}
		if ( $v_file ) {
			fn_get_include( $v_file );
		} else {
			print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
		}
	} elsif ( $v_arg eq "--output" || $v_arg eq "-o" ) {
		if ( defined $ARGV[0] ) {
			$v_file = fn_test_file(shift( @ARGV ));
		}
		if ( $v_file ) {
			$f_output = $v_file;
		} else {
			print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
		}
	} elsif ( $v_arg eq "-v" || $v_arg eq "--verbose" ) {
		if (!$b_verbose) {
			$b_verbose = 1;
		} else {
			$b_verbose = 0;
		}
	} else {
		push( @args, $v_arg );
	}
}

### Process the commandline arguments
my @v_unknown;
if ( defined $args[0] && $args[0] eq "--diff" ) {
### The part where we diff output files
	shift( @args );
	my $v_file1;
	my $v_file2;
	my $b_no_sort;
	while ( defined $args[0] ) {
		my $v_arg = shift( @args );
		if ( $v_arg eq "--format" || $v_arg eq "-f" ) {
			if ( defined $args[0] ) {
				$v_format = shift( @args );
			} else {
				print STDERR "Argument '" . $v_arg . "' must be followed by 'text' or 'html'\n";
			}
		} elsif ( $v_arg eq "--no-check-retention" ) {
			$b_retention = 0;
		} elsif ( $v_arg eq "--no-partial-seconds" ) {
			$b_partial_seconds = 0;
		} elsif ( $v_arg eq "--no-ctime" ) {
			$b_diff_ctime = 0;
		} elsif ( $v_arg eq "--backup" ) {
			$b_backup = 1;
		} elsif ( $v_arg eq "--before" && defined $args[0] ) {
			if ($v_file1) {
				$v_file2 = $v_file1;
			}
			$v_file1 = shift( @args );
			$b_no_sort = 1;
		} elsif ( $v_arg eq "--after" && defined $args[0] ) {
			$v_file2 = shift( @args );
			$b_no_sort = 1;
		} elsif ( -e $v_arg ) {
			if (! $v_file1) {
				$v_file1 = $v_arg;
			} else {
				$v_file2 = $v_arg;
			}
		} else {
			push ( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ( ! defined $v_file1 || ! defined $v_file2 || ! -r $v_file1 || ! -r $v_file2 ) {
		print STDERR "With \"--diff\", must specify two files\n";
		exit 1;
	} elsif ( ! $b_no_sort ) {
		( $v_file1, $v_file2 ) = fn_date_files( $v_file1, $v_file2 );
	}
	if ( ! $d_backup || ! -d $d_backup || ! -w $d_backup || (! @v_backupr && ! @v_backup_plus) ) {
		$b_backup = 0;
	}
	if ( ! $v_format || ($v_format ne "text" && $v_format ne "html" && $v_format ne "diff") ) {
		$v_format = "text";
	}
	### Check if the ability to use md5sums is present
	$b_use_md5 = fn_mod_check( 'Digest::MD5', 'Digest::MD5::File', 0 );
	if ( $b_use_md5 && ! -f $d_program . '/scripts/md5.pm' ) {
		$b_use_md5 = 0;
	} elsif ( $b_use_md5 ) {
		require( $d_program . '/scripts/md5.pm' );
	}
	### Check to make sure that the necessary binaries are here
	fn_bin_check ('stat', 'diff');
	### Sort the relevant arrays
	my $b_close = fn_sort_prep();
	fn_document_backup();
	my $v_file1_escape = fn_escape_filename($v_file1);
	my $v_file2_escape = fn_escape_filename($v_file2);
	fn_log("Processing diff of files " . $v_file1_escape . " and " . $v_file2_escape . "\n");
	fn_diff( $v_file1, $v_file2 );
	fn_log("Finished processing diff\n");
	if ($b_close) {
		close $fh_output;
	}
} elsif ( defined $args[0] && $args[0] eq "--list" ) {
	shift( @args );
	my @v_files;
	while ( defined $args[0] ) {
		my $v_arg = shift( @args );
		if ( $v_arg && -e $v_arg && ! -p $v_arg ) {
			my @v_dirs = split( m/\//, $v_arg );
			my $v_name = pop( @v_dirs );
			my $v_file = join( '/', @v_dirs );
			$v_file = ( abs_path( $v_file ) || $v_file ) . "/" . $v_name;
			push( @v_files, $v_file );
			if ( -l $v_file ) {
				$v_file = fn_test_file($v_file, 0, 'f');
				if ( $v_file ) {
					push( @v_files, $v_file );
				}
			}
		} else {
			push( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ( ! @v_files ) {
		print STDERR "A file must be given to look for\n";
		exit 1;
	}
	require( $d_program . '/scripts/fold_print.pm' );
	for my $_file (@v_files) {
		fn_list_file($_file);
	}
	print "\n";
} elsif ( defined $args[0] && ( $args[0] eq "--backup" || $args[0] eq "--backup-file" ) ) {
### Backup files from "--report" output. or backup a single file
	my $v_type = shift( @args );
	my $v_file;
	my @v_files;
	my $v_comment;
	while ( defined $args[0] ) {
		my $v_arg = shift( @args );
		if ( $v_arg eq "--backupd" ) {
			if ( defined $args[0] ) {
				my $v_file = fn_test_file( shift( @args ), 1, 'd' );
				if ( $v_file ) {
					$d_backup = $v_file;
				}
			} else {
				print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
			}
		} elsif ( $v_arg eq "--backup+" ) {
			if ( defined $args[0] ) {
				my $v_file = fn_test_file( shift( @args ), 0, 'f' );
				if ( $v_file ) {
					push( @v_backup_plus, $v_file );
				}
			} else {
				print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
			}
		} elsif ( $v_arg eq "--backupr" ) {
			if ( defined $args[0] ) {
				push( @v_backupr, shift( @args ) );
			} else {
				print STDERR "Argument '" . $v_arg . "' must be followed by a file name\n";
			}
		} elsif ( $v_arg eq "--comment" && $v_type eq "--backup-file" ) {
			if ( $v_comment ) {
				print STDERR "Only one comment can be specified\n";
			} elsif ( defined $args[0] ) {
				$v_comment =  shift( @args );
			} else {
				print STDERR "Argument '" . $v_arg . "' must be followed by a comment\n";
			}
		} elsif ( -e $v_arg ) {
			if ( $v_type eq "--backup" ) {
				$v_file = $v_arg;
			} else {
				push( @v_files, $v_arg );
			}
		} else {
			push ( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	$b_retention = 0;
	if ( ! $d_backup || (! @v_backupr && ! @v_backup_plus) ) {
		if ( $v_type eq "--backup" ) {
			print STDERR "The job file must have \"BackupD\" and \"BackupR\" or \"Backup+\" control strings present\n";
			exit 1;
		} elsif ( ! $d_backup ) {
			print STDERR "The job file must have the \"BackupD\" control string present\n";
			exit 1;
		}
	} elsif ( ! -d $d_backup || ! -w $d_backup ) {
		print STDERR "The backup directory does not exist or is not writable\n";
		exit 1;
	}
	my $b_close = fn_sort_prep();
	if ($b_close) {
		close $fh_output;
	}
	### Check if the ability to use md5sums is present
	$b_use_md5 = fn_mod_check( 'Digest::MD5', 'Digest::MD5::File', 0 );
	if ( $b_use_md5 && ! -f $d_program . '/scripts/md5.pm' ) {
		$b_use_md5 = 0;
	} elsif ( $b_use_md5 ) {
		require( $d_program . '/scripts/md5.pm' );
	}
	### Output to the log and begin the job
	if ( $v_type eq "--backup" ) {
		my $d_backup_escape = fn_escape_filename($d_backup);
		fn_log("Checking to see if there are files that need to be backed up " . $d_backup_escape . "\n");
		fn_document_backup();
		fn_backup_initial($v_file);
	} else {
		for my $_file ( @v_files ) {
			if ( $b_use_md5 ) {
				$b_md5_all = 1;
			}
			@v_backup_plus = ($_file);
			my $f_backup = fn_backup_file( $_file, $d_backup );
			if ( $b_verbose ) {
				print $f_backup . "\n"; ##### Is this good enough?
			}
			if ($v_comment) {
				if ( open( my $fh_write, ">>", $f_backup . "_comment" ) ) {
					print $fh_write "    - " . $v_comment . "\n";
				}
			}
		}
	}
} elsif ( defined $args[0] && $args[0] eq "--md5-test" ) {
	if ( -f $d_program . '/scripts/md5.pm' ) {
		fn_mod_check( 'Digest::MD5', 'Digest::MD5::File' );
		require( $d_program . '/scripts/md5.pm' );
		### Check to make sure that the necessary binaries are here
		fn_bin_check ('stat', 'diff');
		print "It looks as if everything you need is in place for MD5 functionality\n";
		exit;
	} else {
		print STDERR "\nCannot check md5sums without module '" . $d_program . "/scripts/md5.pm':\n";
		print STDERR "https://raw.githubusercontent.com/sporks5000/stat_watch/master/scripts/md5.pm\n\n";
		exit 1;
	}
} elsif ( defined $args[0] && $args[0] eq "--prune" ) {
	shift( @args );
	while ( defined $args[0] ) {
		push ( @v_unknown, shift( @args ) );
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ($d_backup) {
		my $d_backup_escape = fn_escape_filename($d_backup);
		fn_log("Pruning old backups from directory " . $d_backup_escape . "\n");
		fn_prune_backups($d_backup);
	}
} elsif ( defined $args[0] && ($args[0] eq "--record" || $args[0] eq "--links" || $args[0] eq "--new-lines" || substr($args[0],0,2) ne "--") ) {
### The part where we capture the stats of files
	while ( defined $args[0] ) {
		my $v_arg = shift( @args );
		if ( $v_arg eq "--ignore-on-record" ) {
			$b_ignore_on_record = 1;
		} elsif ( $v_arg eq "--md5" ) {
			$b_md5_all = 1;
		} elsif ( $v_arg eq "--as-dir" && defined $args[0] ) {
			$v_as_dir = shift( @args );
		} elsif ( -e $v_arg ) {
			my $v_dir = (abs_path($v_arg) || $v_arg );
			push( @v_dirs, $v_dir );
		} elsif ( $v_arg eq "--record" ) {
		} elsif ( $v_arg eq "--links" ) {
			$b_ignore_on_record = 1;
			$b_links = 1;
		} elsif ( $v_arg eq "--new-lines" ) {
			$b_ignore_on_record = 1;
			$b_new_lines = 1;
		} else {
			push ( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ( ! @v_dirs ) {
		print STDERR "No directories selected. See \"--help\" for usage\n";
		exit 1;
	}
	### Expand and sort the directories; sort the ignore lists
	for my $_dir (@v_dirs) {
		$_dir =~ s/\/\/+/\//g;
		$_dir =~ s/\/$//;
	}
	my $b_close = fn_sort_prep();
	### If we're supposed to be getting md5sums, check to ensure that that's possible
	if ( @v_md5r || $b_md5_all || @v_md5 ) {
		if ( -f $d_program . '/scripts/md5.pm' ) {
			fn_mod_check( 'Digest::MD5', 'Digest::MD5::File' );
			require( $d_program . '/scripts/md5.pm' );
			$b_use_md5 = 1;
		} else {
			print STDERR "\nCannot check md5sums without module '" . $d_program . "/scripts/md5.pm':\n";
			print STDERR "https://raw.githubusercontent.com/sporks5000/stat_watch/master/scripts/md5.pm\n\n";
			sleep 2;
		}
	}
	### Check to make sure that the necessary binaries are here
	fn_bin_check ('stat', 'diff');
	### Process those directories
	for my $_dir ( @v_dirs ) {
		$v_current_dir = $_dir;
		my $v_timestamp = time();
		my $v_output_dir = fn_get_file_name($_dir);
		if ( ! $b_links && ! $b_new_lines ) {
			print $fh_output "Processing: '" . $v_output_dir . "' - " . $v_timestamp . "\n";
		}
		fn_check_strings( $_dir );
		if ( -d $_dir && (! $b_links || ! $b_new_lines) ) {
			### Individual files can be listed as well, but there's no need to log the fact we're looking at those. Just directories will suffice
			my $_dir_escape = fn_escape_filename($_dir);
			fn_log("Running a report for directory " . $_dir_escape . "\n");
		}
		fn_stat_watch( $_dir, $v_timestamp );
	}
	fn_log("Finished all reports\n");
	### Close the output file
	if ($b_close) {
		close $fh_output;
	}
} else {
	print STDERR "See \"--help\" for usage\n";
	exit 1;
}
