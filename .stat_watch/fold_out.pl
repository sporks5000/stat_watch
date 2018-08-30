#! /usr/bin/perl
### given a file name, or series of file names, or piped in data, fold print those files

use strict;
use warnings;

our $d_progdir = __FILE__;
$d_progdir = ( readlink($d_progdir) || $d_progdir );
my @progdir = split( m/\//, $d_progdir );
pop( @progdir );
$d_progdir = join( "/", @progdir );

sub fn_import_fold_print {
	if ( $d_progdir . '/fold_print.pm' ) {
		require( $d_progdir . '/fold_print.pm' );
		print fn_fold_print($_[0]);
	} else {
		print $_[0];
	}
}

### First print anything piped in
if ( ! -t STDIN ) {
	my $v_message = '';
	while (<STDIN>) {
		$v_message .= $_;
	}
	fn_import_fold_print($v_message);
}

### Then print any files that were given
if (@ARGV) {
	while (@ARGV) {
		my $arg = shift(@ARGV);
		if ( -f $arg && -r $arg && open( my $fh_read, "<", $arg ) ) {
			my $v_message = '';
			while (<$fh_read>) {
				$v_message .= $_;
			}
			fn_import_fold_print($v_message);
		}
	}
}
