#! /usr/bin/perl
### Given a directory, get stats for all files and subdirectories
### Useful for seeing what has changed since the last time this was run
### Created by ACWilliams

use strict;
use warnings;

my $v_VERSION = "1.2.0";

use Cwd 'abs_path';
use POSIX 'strftime';

my $v_program = __FILE__;
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

#===================#
#== Report Output ==#
#===================#

sub fn_check_file {
### Check a file to see if it matches any of the ignore lists
### $_[0] is the full path to the file
	my $v_file = $_[0];
	my $v_file_escape = $v_file;
	if ($b_verbose) {
		$v_file_escape =~ s/'/'\\''/g;
	}
	for my $_string (@v_temp_ignore){
		if ( $v_file eq $_string ) {
			if ($b_verbose) {
				print STDERR "IGNORED: '" . $v_file_escape. "'\n";
			}
			return 0;
		}
	}
	for my $_string (@v_temp_rignore) {
		if ( $v_file =~ m/$_string/ ) {
			if ($b_verbose) {
				print STDERR "IGNORED: '" . $v_file_escape . "'\n";
			}
			return 0;
		}
	}
	for my $_string (@v_temp_star_ignore){
		if ( $v_file =~ m/$_string/ ) {
			if ($b_verbose) {
				print STDERR "IGNORED: '" . $v_file_escape . "'\n";
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
			return( ' -- ' . &sw_md5::get_md5($v_file) );
		}
		for my $_string (@v_md5) {
			if ( $v_file eq $_string ) {
				return( ' -- ' . &sw_md5::get_md5($v_file) );
			}
		}
		for my $_string (@v_md5r) {
			if ( $v_file =~ m/$_string/ ) {
				return( ' -- ' . &sw_md5::get_md5($v_file) );
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
	my $v_file_escape = $v_file;
	$v_file_escape =~ s/'/'\\''/g;
	my $v_line = `stat -c \%A" -- "\%u" -- "\%g" -- "\%s" -- "\%y" -- "\%z '$v_file_escape' 2> /dev/null`;
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
	if ($b_verbose) {
		my $v_dir_escape = $v_dir;
		$v_dir_escape =~ s/'/'\\''/g;
		print STDERR "Directory: '" . $v_dir_escape . "'\n";
	}
	if ( -e $v_dir && ! -d $v_dir ) {
	### If we were given a file instead of a directory
		my $v_file = $v_dir;
		if ( fn_check_file($v_file) ) {
			fn_report_line($v_file, $v_timestamp);
		}
	} elsif ( -e $v_dir ) {
		if ( $v_dir eq $v_current_dir ) {
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
					if ( $b_ignore_on_record && ! fn_check_file($v_file) ) {
						next;
					}
					### Capture it if it's a directory
					if ( -d $v_file && ! -l $v_file ) {
						push( @dirs, $v_file );
					}
					fn_report_line($v_file, $v_timestamp);
				}
			}
			for my $_dir (@dirs) {
			### For each of the directories we found, go through RECURSIVELY!
				### Make sure that the file doesn't match any of the ignore lists
				if ( ! fn_check_file($_dir) ) {
					next;
				}
				$v_cur_depth++;
				if ( $v_cur_depth <= $v_max_depth ) {
					fn_stat_watch( $_dir, $v_timestamp);
				} else {
					fn_log("Maximum depth reached at '" . $_dir . "'\n");
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
	my $diff1_escape = $f_diff1;
	$diff1_escape =~ s/'/'\\''/g;
	my $diff2_escape = $f_diff2;
	$diff2_escape =~ s/'/'\\''/g;
	### With the file sizes we're looking at, most of the time the diff binary will be quicker than any tool Perl itself can provide
	my @v_diff = `diff '$diff1_escape' '$diff2_escape' 2> /dev/null`;
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
					push( @v_deep_dirs, $v_file );
				}
				next;
			}
			my $v_line = pop(@v_line);
			### Remove up to the first single quote
			shift(@v_line);
			### Most files won't have single quotes in them, but just in case...
			my $v_file = join( "'", @v_line );
			if ( ! exists $ref_diff->{$v_file} ) {
				my $v_file_escape = $v_file;
				$v_file_escape =~ s/'/'\\''/g;
				$ref_diff->{$v_file}->{'escape'} = "'" . $v_file_escape . "'";
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
		my $f_read_escape = $f_read;
		$f_read_escape =~ s/'/'\\''/g;
		$v_error = "File '" . $f_read_escape . "' does not appear to be a Stat Watch file\n";
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
		fn_backup_file($v_file, $d_backup, 1);
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
			my $v_file_escape = $v_file;
			$v_file_escape =~ s/'/'\\''/g;
			fn_log("Removing backed-up file '" . $v_file_escape . "'\n");
			unlink( $v_file );
		}
		$v_count++;
	}
}

sub fn_prune_backups {
### This is the main function that's run with the "--prune" option
### $_[0] is the backup directory
	my $v_dir = $_[0];
	if ($b_verbose) {
		my $v_dir_escape = $v_dir;
		$v_dir_escape =~ s/'/'\\''/g;
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
### $_[0] is the file we're copying, $_[1] is the backup directory, $_[2] is whether or not the current file chould be checked against a previous file
	my $v_file = $_[0];
	my $d_backup = $d_backup;
	if ( $_[1] ) {
		$d_backup = $_[1];
	}
	my $b_check;
	if ( $_[2] ) {
		$b_check = $_[2];
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
		my $v_file_escape = $v_file;
		$v_file_escape =~ s/'/'\\''/g;
		if ( -d $d_backup ) {
			if ( $b_check ) {
				$b_continue = fn_compare_backup($v_file, $d_backup);
				if ( $b_continue ) {
					### No need to back it up, because it already matches
					return 1;
				}
			}
			$d_backup .= "/" . $v_name . "_" . time();
			### When ever running a command with backticks, we need to make sure arguments we're passing to it are quote safe:
			system( "cp", "-a", $v_file, $d_backup );
			### Test if the files was successfully copied
			if ( -f $d_backup || -l $d_backup ) {
				if ($b_verbose) {
					my $d_backup_escape = $d_backup;
					$d_backup_escape =~ s/'/'\\''/g;
					print STDERR "'" . $v_file_escape . "' -> '" . $d_backup_escape . "'\n";
				}
				fn_log("Backed up file '" . $v_file_escape . "'\n");
				if ($b_retention) {
					fn_check_retention( $d_backup .= "/" . $v_name );
				}
				return 1;
			}
		}
		fn_log("Failed to backup file '" . $v_file_escape . "'\n");
		if ($b_verbose) {
			print STDERR "Failed to backup file '" . $v_file_escape . "'\n";
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
		$v_name = qr/^\Q$v_name\E_[0-9]+$/;
		for my $_file (@files) {
			if ( $_file =~ m/$v_name/ ) {
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
			return 1;
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
		my @v_dir = split( m/\//, $v_program );
		pop( @v_dir );
		my $v_dir = join( '/', @v_dir );
		$v_dir = $v_dir . "/.stat_watch";
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
	my $v_file_escape = $v_file;
	$v_file_escape =~ s/'/'\\''/g;
	print "\nAvailable Backups for '" . $v_file_escape . "':\n";
	if (@v_files) {
		@v_files = sort {$a cmp $b} @v_files;
		for my $_file (@v_files) {
			my $v_stamp = (split( m/_/, $_file ))[-1];
			$v_stamp = strftime( '%Y-%m-%d %T %z', localtime($v_stamp) );
			my $_file_escape = $_file;
			$_file_escape =~ s/'/'\\''/g;
			print "  '" . $_file_escape . "' -- Timestamp: " . $v_stamp . "\n";
		}
	} else {
		print "There are no backups of this file\n"
	}
	print "\n";
}
#================================#
#== Processing the ignore file ==#
#================================#

sub fn_get_include {
### Read the ignore/include file and extract data from it
### $_[0] is the file in question.
	my $f_ignore = $_[0];
	if ( ! -r $f_ignore ) {
		my $f_ignore_escape = $f_ignore;
		$f_ignore_escape =~ s/'/'\\''/g;
		print STDERR "Cannot read file '" . $f_ignore_escape . "'\n";
	}
	### Make sure we don't read a file twice
	for my $_include (@v_includes) {
		if ( $f_ignore eq $_include ) {
			return;
		}
	}
	push( @v_includes, $f_ignore );
	### Read the include file
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
					push( @v_ignore, abs_path($_line) );
				} elsif ( $_line =~ m/^\*\s*\// ) {
				### Ignore all files whose full path starts with this string
					$_line =~ s/^\*\s*//;
					push( @v_star_ignore, abs_path($_line) );
				} elsif ( $_line =~ m/^Include\s*\// ) {
				### Process these files as additional include/ignore lists
					$_line =~ s/^Include\s*//;
					fn_get_include( abs_path($_line) );
				} elsif ( $_line =~ m/^I\s*\// ) {
				### Also report on these files / directories
					$_line =~ s/^I\s*//;
					push( @v_dirs, abs_path($_line) );
				} elsif ( $_line =~ m/^BackupD\s*\// ) {
				### Set a directory to back up to
					$_line =~ s/^BackupD\s*//;
					$d_backup = abs_path($_line);
				} elsif ( $_line =~ m/^Backup\+\s*\// ) {
				### Specify a file that should be backed up if there are changes
					$_line =~ s/^Backup\+\s*//;
					push(@v_backup_plus, abs_path($_line));
				} elsif ( $_line =~ m/^MD5\s*\// ) {
				### Specify a file that we want to capture the md5 sum of
					$_line =~ s/^MD5\s*//;
					push(@v_md5, abs_path($_line));
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
					$f_log = abs_path($_line);
				} elsif ( $_line =~ m/^Time-\s*\// ) {
				### Specify a file that we should be unconcerned about changes to the timestamps
					$_line =~ s/^Time-\s*//;
					push(@v_time_minus, abs_path($_line));
				}
			}
		}
		close( $fh_read );
	}
}

sub fn_document_backup {
### Document the backup locations we've seen so that we can check all of them when necessary
	if ( $d_backup ) {
	### If the include file listed a backup directory, add that to the list of backup directories
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
		my $f_output_escape = $f_output;
		$f_output_escape =~ s/'/'\\''/g;
		print STDERR "Cannot open file '" . $f_output_escape . "' for writing\n";
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
		print "  '" . $_arg . "'\n";
	}
	print "\n";
	sleep( 2 );
}

sub fn_get_working {
### Given the full path to the program, return the name of an appropriate working directory
	my $v_program = $_[0];
	my @v_working = split( m/\//, $v_program );
	my $v_name = pop( @v_working );
	$v_name =~ s/\.pl$//;
	my $d_working = join( '/', @v_working );
	$d_working .= "/." . $v_name;
	if ( ! -d $d_working ) {
		mkdir( $d_working, 0755 );
	}
	return $d_working;
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

sub fold_print {
### Given a message to print to the terminal, line-break that message at word breaks
### $_[0] is the message; $_[1] is the number of columns to use if columns can't be determined.
	### Determine how many columns we're working with
	my $v_columns;
	if( exists $ENV{PATH} && defined $ENV{PATH} ) {
		my @v_paths = split( m/:/, $ENV{PATH} );
		for ( @v_paths ) {
			if ( -f ( $_ . "/tput" ) && -x ( $_ . "/tput" ) ) {
				my $v_exe =  $_ . "/tput";
				$v_columns = `$v_exe cols`;
				chomp $v_columns;
				if ( $v_columns =~ m/^[0-9]+$/ ) {
					last;
				}
			}
		}
	}
	if ( $v_columns && $v_columns !~ m/^[0-9]+$/ ) {
		if ( $_[1] ) {
			$v_columns = $_[1];
		} else {
			return $_[0];
		}
	} else {
		$v_columns--;
	}

	### Go through each line of the message and make sure it's breaks appropriately
	my @v_message = split( m/\n/, ( $_[0] . "\n" . "last" ) );
	for my $_line ( @v_message ) {
		chomp( $_line );
		$_line =~ s/\t/     /g;
		$_line = $_line . "\n";
		next if length( $_line ) <= $v_columns;
		my $v_remaining = length( $_line ) - 1;
		my $v_complete = 0;
		my $v_spaces = "";
		for my $_character ( 0 .. ( $v_remaining - 1 ) ) {
			if ( substr( $_line, $_character, 1 ) =~ m/[ *-]/ ) {
				$v_spaces = $v_spaces . " ";
			} else {
				last;
			}
		}
		my $v_length_spaces = length( $v_spaces );
		while ( $v_remaining >= $v_columns ) {
			for my $_character ( reverse( ( $v_complete + $v_length_spaces ) .. ( $v_complete + $v_columns ) ) ) {
				if ( substr( $_line, $_character, 1 ) eq " "  ) {
					$_line = substr( $_line, 0, $_character ) . "\n" . $v_spaces . substr( $_line, ($_character + 1) );
					$v_remaining = ( length( $_line ) - 1 - $_character + 1 );
					$v_complete = ( $_character + 1 );
					last;
				}
				if ( $_character == ( $v_complete + $v_length_spaces ) ) {
					$v_remaining -= $v_columns;
					$v_complete += $v_columns;
				}
			}
		}
	}
	pop @v_message;
	$v_message[$#v_message] = substr( $v_message[$#v_message], 0, (length( $v_message[$#v_message] ) - 1 ) );
	return @v_message;
}

#=============================#
#== Information Subroutines ==#
#=============================#

sub fn_version {
print "Current Version: $v_VERSION\n";
my $v_message = <<'EOF';

Version 1.2.0 (2018-08-19) -
    - Added the "--md5" flag, as well as a few control strings
    - Added a maximum depth for the script to recurse to
        - The "--record" and "--diff" outputs now include instances where such directories are present
    - Split out help text so that you can reference individual bits of it
    - In "--diff" mode, check mtimes of the two reports we're comparing. Always make the newest file on the right for diff purposes
        - Added the "--before" and "--after" flags for "--diff" mode to override this behavior
    - When checking whether a file needs to be backed up, if the md5sum was captured initially, check against the md5sum of the backup as well.

Version 1.1.0 (2018-08-17) -
    - Added the ability to compare md5sums of files as well
    - Fixed a bug where files might be being matched against incorrectly due to an added slash

Version 1.0.1 (2018-08-10) -
    - Added the ability to capture data on files with names that include a newline character
    - Liberal use of abs_path in hopes of ensuring that files are always referenced in the same manner

Version 1.0.0 (2018-08-04) -
    - Original Version

EOF
print fold_print($v_message);
exit 0;
}

sub fn_help {
my $v_header = <<'EOF';

stat_watch.pl - a script for finding and reporting changes in files and directories

EOF
my $v_usage = <<'EOF';

USAGE

./stat_watch.pl --record [DIRECTORY] ([DIRECTORY 2] ...)
    - Outputs stat data for all of the files under the directory specified (you probably want to use the "-o" flag or redirect output to a file)
    - The "-v" or "--verbose" flag can be used to have the directories output to STDERR
    - The "-i" or "--include" flag can be used to specify an ignore/include file
    - The "-o" or "--output" flag will specify a file to poutput to, otherwise /dev/stdout will be used
    - This is the default functionality. Technically the "--record" flag is not necessary
    - The "--md5" flag will result in the MD5 sums of all files being captured in addition to their stats
        - This will require that the .stat_watch/md5.pm file be present, as well as the perl modules 'Digest::MD5' and 'Digest::MD5::File'
        - This will cause the process to take longer and generally isn't necessary - the combination of mtime, ctime, and file size is usually enough to detect if a change has occurred
    - The "--ignore-on-record" flag will result in individual files being checked against ignore rules
        - Otherwise only directories are checked against this rules, and weeding out things to be ignored only occurrs during "--diff"
        - Use of this flag results in larger file sizes for Stat Watch reports, but generally reduces processing time overall
    - The "--as-dir" flag can be followed by a string of text that will be used to replace the directory name when recording the full file path
        - For example, running "./stat_watch.pl --record /home/account --as-dir "/home/different/path" will result in the file "/home/account/file.txt" to be listed as "/home/different/path/file.txt"
        - This is useful for situations where you want to capture information for backed-up files and compare them to files in place.

./stat_watch.pl --diff [FILE 1] [FILE 2]
    - Compare two Stat Watch report files, weed out files that match ignore rules, output information on what has changed
    - The "--ignore" flag can be used to specify a specific file or directory that you want to ignore
        - This is functionally the same as the "BackupD" control string in an include/ignore file
    - The "-i" or "--include" flag can be used to specify an ignore/include file
    - The "-o" or "--output" flag will specify a file to poutput to, otherwise /dev/stdout will be used
    - The "-f" or "--format" flag allows you to choose a number of options for how the details should be output:
        - "text" separates out what has changed and how, and outputs in plain text format
        - "html" separates out what has changed and how, and outputs in html format
        - "diff" outputs the lines that were different with "<" and ">" characters to indicate which file they came from. 
    - The "--backup" flag will result in files being backed up. "BackupD" and "BackupR" or "Backup+" lines must be set in the include file for this to be successful
    - The "--no-check-retention" flag mean that when creating backups, existing files will not be checked for retention
        - This is optimal if you're regularly running this script with the "--prune" flag
    - The "--no-ctime" flag tells the script to ignore differences in ctime. This is useful if you're comparing against a restored backup.
    - The "--no-partial-seconds" limits the comparison of timestamps to full seconds
    - The "--before" and "--after" flags can be used to specify which is the earlier Stat Watch report file and which is the later
        - Without these flags, the mtimes of the files are used to determine which is which

./stat_watch.pl --backup [FILE]
    - Create backups of files specified using a Stat Watch report file and the settings within an ignore/include file
    - The file must be a Stat Watch report file
    - The "-i" or "--include" flag can be used to specify an ignore/include file and that file must have "BackupD" and "BackupR" or "Backup+" control strings present
    - The "--backupd" flag can be used, followed by the directory that you want to back up to
        - This is functionally the same as the "BackupD" control string in an include/ignore file
    - The "--backup+" flag can be used, followed by the full path of a file that you wish to back up. This flag can be used more than once.
        - This is functionally the same as the "Backup+" control string in an include/ignore file
    - The "--backupr" flag can be used, followed by perl regular expression to match in order to decide what files to backup. This flag can be used more than once.
        - This is functionally the same as the "BackupR" control string in an include/ignore file
    - If you modify the "BackupR" or "Backup+" settings and re-run "--backup", it will compare stats of existing backups and only save files that are different / not present
        - However, files that are no longer matched will not be removed

./stat_watch.pl --list [FILE]
    - This will list the available backups for a specific file
    - It is not necessary to specify an includde file, Stat Watch will check all directories that it has ever backed up to in hopes of giving the most comprehensive answer possible.

./stat_watch.pl --prune [FILE]
    - Go through the backup directory and remove files older files
    - The file must be a Stat Watch report file
    - The "-i" or "--include" flag must be used to specify an ignore/include file and that file must have "BackupD" string present
    - Any files outside of the range specified by the "BackupMD" and "BackupMC" control strings will be removed

./stat_watch.pl --help
./stat_watch.pl -h
    - Outputs full help information

./stat-watch.pl --help-usage
./stat-watch.pl --help-includes
./stat-watch.pl --help-backups
    - Outputs information regarding the specific aspect of Stat Watch requested

EOF
my $v_include = <<'EOF';

REGARDING THE IGNORE/INCLUDE FILE

Default Usage:
    - All files or directories need to be referred to by full path (Beginning with "/") unless specified otherwise
    - Any line beginning with a file or directory will result in that file or directory (and all files within) being passed over
    - You can include any amount of whitespace at the start or end of a line, it will not be interpreted
    - Spaces and special characters don't need to be quoted or escaped
    - All other lines that don't match this or the control strings described below will be ignored.

Control Strings:
    - Lines beginning with the following control strings have special meanings and can be declared multiple times: 
        - "*" - Pass over all files and directories whose full path begins with the string that follows
        - "R" - Pass over all files and directories that match the following Perl interpreted regex
        - "I" - Add the following file or directory to the list of files and directories to be checked (as if it was listed at the command line). Has no effect with "--diff"
        - "Include" - Interpret the contents of the following file as if it was listed at the command line as an include/ignore file
        - "BackupR" - If a file matches the regular expression that follows, and the appropriate flags are set, they will be backed up
        - "Backup+" - In any instance where there are changes to the following file, it will be backed up
        - "Time-" - Stat changes to this file will not be reported if the only change is to mtime or ctime
            - Useful if a file is regularly getting touched by a process, but still want to track changes to it otherwise
        - "MD5R" - If a file matches the regular expression that follows, also capture the file's MD5 sum for comparison
        - "MD5" -
            - If a file's name and full path matches the exact string that follows, also capture the file's MD5 sum for comparison
            - If this is alone on a line, then capture MD5 sums for everything (as if the "--md5" flag was used)
            - This will require that the .stat_watch/md5.pm file be present, as well as the perl modules 'Digest::MD5' and 'Digest::MD5::File'
    - Lines beginning with the following control strings have special meanings, but only the last declaration will be interpreted:
        - "BackupD" - This specifies the directory to backup files to. The directory must already exist and be writable, or Stat Watch will error out
        - "BackupMD" - A number specified here will set the minumum number of days a backed up file should be kept
        - "BackupMC" - A number here will set the maximum number of copies of a file that should be backed up (after the minumum retention has been met)
        - "Log" - Placing a full path to a file after this will tell Stat Watch where to log
        - "Max-depth" - A number here will set the maximum depth of directories that the script can recurse into (default 20)
            - Any directories deeper than this will be logged on each run, assuming that the "Log" control string is used
    - Control strings can have any amount of whitespace before or after them on the line. It will not be interpreted.
    - When a file is included via "Include", the entirety of that file will be interpreted before the going on to interpret the next line
    - For "*" or "R", any line matching a directory will result in that directory and all files and subdirectories it contains being passed over

Other Rules:
    - Any line that doesn't match what's described above will be ignored
    - Lines cannot begin with more than one control string
    - If a directory is included with "I" or given at the command line that would otherwise be ignored due to entries in the file, those entries will be ignored while it is being checked

EOF
my $v_backup =  <<'EOF';

REGARDING BACKUPS

When do backups occur?
    - For backups to occur, you must have an include/ignore file that contains lines with the control characters "BackupD" and "BackupR" or "Backup+"
    - When Stat Watch is run in "--backup" mode, all files matching the "BackupR" or "Backup+" lines will have their file type, permissions, user, group, size, and mtime checked against the most recent backup (if any). If any of these are different, the file will be backed up
    - When Stat Watch is run in "--diff" mode, any files with changes to their file type, permissions, user, group, size, mtime, or ctime will be backed up
    - Changing the "BackupR" or "Backup+" lines and then running "--diff" without running "--backup" WILL NOT cause matching files to be backed up (until "--diff" recognizes that a change has happened)

When are backups pruned?
    - Every time a file is backed up, the directory is checked afterward for other backups of the same file
    - Of those other backups, the newest X are ignored, where X is the number set by the "BackupMC" control string
    - Any of the remaining backups that are older then Y days are removed, where Y is the number set by the BackupMD control string
    - Because old backups will not typically be removed unles a new backup of the file is made, there is also the option to run stat_watch.pl with the "--prune" flag

Automating backups
    - The Stat Watch project includes a script named stat_watch_wrap.sh. This is the most straight-forward way to set up reoccurring Stat Watch checks including backups and email notifications.

EOF
my $v_feedback = <<'EOF';

FEEDBACK

The Stat Watch project is available at the following git repositories (one of which is public facing):
    - https://github.com/sporks5000/stat_watch
    - https://git.liquidweb.com/acwilliams/stat_watch

Report any errors, unexpected behaviors, comments, or feedback to acwilliams@liquidweb.com

EOF

if ( ! $_[0] ) {
	print fold_print($v_header . $v_usage . $v_include . $v_backup . $v_feedback);
} elsif ( $_[0] eq "usage" ) {
	print fold_print($v_header . $v_usage . $v_feedback);
} elsif ( $_[0] eq "includes" ) {
	print fold_print($v_header . $v_include . $v_feedback);
} elsif ( $_[0] eq "backups" ) {
	print fold_print($v_header . $v_backup . $v_feedback);
}
exit 0;
}

#==================================#
#== Parse command line arguments ==#
#==================================#

### Find the working directory, in case it's needed
$d_working = fn_get_working($v_program);

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
	} elsif ( $v_arg eq "--help" || $v_arg eq "-h" ) {
		fn_help();
		exit 0;
	} elsif ( $v_arg eq "--help-usage" ) {
		fn_help('usage');
		exit 0;
	} elsif ( $v_arg eq "--help-includes" ) {
		fn_help('includes');
		exit 0;
	} elsif ( $v_arg eq "--help-backups" ) {
		fn_help('backups');
		exit 0;
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
	} elsif ( $v_arg eq "--version" ) {
		fn_version();
		exit 0;
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
	if ( $b_use_md5 && ! -f $d_working . '/md5.pm' ) {
		$b_use_md5 = 0;
	} elsif ( $b_use_md5 ) {
		require( $d_working . '/md5.pm' );
	}
	### Sort the relevant arrays
	my $b_close = fn_sort_prep();
	fn_document_backup();
	my $v_file1_escape = $v_file1;
	$v_file1_escape =~ s/'/'\\''/g;
	my $v_file2_escape = $v_file2;
	$v_file2_escape =~ s/'/'\\''/g;
	fn_log("Processing diff of files '" . $v_file1_escape . "' and '" . $v_file2_escape . "'\n");
	fn_diff( $v_file1, $v_file2 );
	fn_log("Finished processing diff\n");
	if ($b_close) {
		close $fh_output;
	}
} elsif ( defined $args[0] && $args[0] eq "--list" ) {
	shift( @args );
	my $v_file;
	while ( defined $args[0] ) {
		my $v_arg = shift( @args );
		my $v_file2 = fn_test_file($v_arg, 0, 'f');
		if ( $v_file2 ) {
			$v_file = $v_file2;
		} else {
			push ( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ( ! $v_file ) {
		print STDERR "A file must be given to look for\n";
		exit 1;
	}
	fn_list_file($v_file);
} elsif ( defined $args[0] && $args[0] eq "--backup" ) {
### Backup files from "--report" output.
	shift( @args );
	my $v_file;
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
		} elsif ( -e $v_arg ) {
			$v_file = $v_arg;
		} else {
			push ( @v_unknown, $v_arg );
		}
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	$b_retention = 0;
	if ( ! $d_backup || (! @v_backupr && ! @v_backup_plus) ) {
		print STDERR "The include file must have \"BackupD\" and \"BackupR\" or \"Backup+\" control strings present\n";
		exit 1;
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
	if ( $b_use_md5 && ! -f $d_working . '/md5.pm' ) {
		$b_use_md5 = 0;
	} elsif ( $b_use_md5 ) {
		require( $d_working . '/md5.pm' );
	}
	### Output to the log and begin the job
	my $d_backup_escape = $d_backup;
	$d_backup_escape =~ s/'/'\\''/g;
	fn_log("Checking to see if there are files that need to be backed up '" . $d_backup_escape . "'\n");
	fn_document_backup();
	fn_backup_initial($v_file);
} elsif ( defined $args[0] && $args[0] eq "--prune" ) {
	shift( @args );
	while ( defined $args[0] ) {
		push ( @v_unknown, shift( @args ) );
	}
	if (@v_unknown) {
		fn_report_unknown(@v_unknown);
	}
	if ($d_backup) {
		my $d_backup_escape = $d_backup;
		$d_backup_escape =~ s/'/'\\''/g;
		fn_log("Pruning old backups from directory '" . $d_backup_escape . "'\n");
		fn_prune_backups($d_backup);
	}
} elsif ( defined $args[0] && ($args[0] eq "--record" || substr($args[0],0,2) ne "--") ) {
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
			push( @v_dirs, abs_path($v_arg) );
		} elsif ( $v_arg eq "--record" ) {
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
		if ( -f $d_working . '/md5.pm' ) {
			fn_mod_check( 'Digest::MD5', 'Digest::MD5::File' );
			require( $d_working . '/md5.pm' );
			$b_use_md5 = 1;
		} else {
			print STDERR "\nCannot check md5sums without module '" . $d_working . "/md5.pm':\n";
			print STDERR "https://raw.githubusercontent.com/sporks5000/stat_watch/master/.stat_watch/md5.pm\n\n";
			sleep 2;
		}
	}
	### Process those directories
	for my $_dir ( @v_dirs ) {
		$v_current_dir = $_dir;
		my $v_timestamp = time();
		my $v_output_dir = fn_get_file_name($_dir);
		print $fh_output "Processing: '" . $v_output_dir . "' - " . $v_timestamp . "\n";
		fn_check_strings( $_dir );
		if ( -d $_dir ) {
			### Individual files can be listed as well, but there's no need to log the fact we're looking at those. Just directories will suffice
			my $_dir_escape = $_dir;
			$_dir_escape =~ s/'/'\\''/g;
			fn_log("Running a report for directory '" . $_dir_escape . "'\n");
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
