#! /usr/bin/perl
### pipe a filename into this, output an escaped filename
### You can do multiple file names, but they have to be null character separated rather than line separated
### If you want new lines after each file name, use the "-n" flag

use strict;
use warnings;

my $d_progdir = '####INSTALLATION_DIRECTORY####/scripts';
if ( substr($d_progdir, 0, 1) ne "/" ) {
	$d_progdir = __FILE__;
	$d_progdir = ( readlink($d_progdir) || $d_progdir );
	my @progdir = split( m/\//, $d_progdir );
	pop( @progdir );
	$d_progdir = join( "/", @progdir );
}

require( $d_progdir . '/../modules/escape.pm' );

my $b_nl;
if ( $ARGV[0] && $ARGV[0] eq "-n" ) {
	$b_nl = 1;
}

### Print what was piped in
if ( ! -t STDIN ) {
	$/ = "\000";
	while (<STDIN>) {
		my $v_file = $_;
		print &SWEscape::fn_escape_filename($v_file);
		if ($b_nl) {
			print "\n";
		}
	}
}
